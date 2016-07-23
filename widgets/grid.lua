---------------------------------------------------------------------------
-- A two dimension layout disposing the widgets in a grid pattern.
--
--@DOC_wibox_layout_defaults_grid_EXAMPLE@
-- @author Emmanuel Lepage Valle
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @classmod wibox.layout.grid
---------------------------------------------------------------------------

local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)
local base  = require("wibox.widget.base")
local table = table
local pairs = pairs
local util = require("awful.util")

local grid = {}

local function get_cell_sizes(self, context, orig_width, orig_height)
    local width, height = orig_width, orig_height

    local max_col, max_row = {}, {}

    --TODO include spacing
    --TODO compute the current sum for each column to have a "less wrong"
    -- widget width.

    local max_h = 0
    for row_idx, row in ipairs(self._private.rows) do
        for col_idx, v in ipairs(row) do
            local w, h = base.fit_widget(self, context, v, width, height)
            max_col[col_idx] = math.max(max_col[col_idx] or 0, w)
            max_row[row_idx] = math.max(max_row[row_idx] or 0, h)
            max_h = math.max(max_h, h)
        end
        height = height - max_h
    end

    return max_col, max_row
end

-- TODO
-- @param context The context in which we are drawn.
-- @param width The available width.
-- @param height The available height.
function grid:layout(context, width, height)
    local max_col, max_row = get_cell_sizes(self, context, width, height)

    local result = {}
    local spacing = self._private.spacing --TODO support spacing

    local y = 0
    for row_idx = 1, #max_row do -- Vertical
        local x = 0
        for col_idx = 1, #max_col do -- Horizontal
            local v = self._private.rows[row_idx][col_idx]

            if v then
                table.insert(result, base.place_widget_at(v, x, y, max_col[col_idx], max_row[row_idx]))
                x = x + max_col[col_idx]
            else
                break
            end
        end

        y = y + max_row[row_idx]
    end

    return result
end

local function get_next_empty(self, row, column)
    row, column = row or 1, column or 1
    local cc = self._private.column_count
    for i = row, math.huge do
        local r = self._private.rows[i]

        if not r then
            r = {}
            self._private.rows[i] = r
            self._private.row_count = i
        end

        for j = column, cc do
            if not r[j] then
                return i, j
            end
        end
    end
end

local function index_to_point(data, index)
    return math.floor(index / data._private.row_count) + 1,
        index % data._private.column_count + 1
end

--- Add some widgets to the given grid layout
-- @param ... Widgets that should be added (must at least be one)
function grid:add(...)
    -- No table.pack in Lua 5.1 :-(
    local args = { n=select('#', ...), ... }
    assert(args.n > 0, "need at least one widget to add")

    local row, column

    for i=1, args.n do
        row, column = get_next_empty(self, row, column)

        base.check_widget(args[i])

        self._private.rows[row][column] = args[i]
    end

    self:emit_signal("widget::layout_changed")
end

function grid:set_cell_widget(row, column, widget)
    if row < self._private.row_count then
        grid:set_row_count(row)
    end

    if column < self._private.column_count then
        grid:set_column_count(column)
    end

    self._private.rows[row] = self._private.rows[row] or {}

    self:emit_signal("widget::layout_changed")
end

function grid:set_row_count(count)
    self._private.row_count = count
end

function grid:set_column_count(count)
    self._private.column_count = count
end

--- Re-pack all the widget according to the current `row_count` and `column_count`.
function grid:reflow()
    --TODO
    self:emit_signal("widget::layout_changed")
end

--- Remove a widget from the layout
-- @tparam number index The widget index to remove
-- @treturn boolean index If the operation is successful
function grid:remove(index, reclaim)
    local TODO_TOTAL = math.huge --FIXME
    if not index or index < 1 or index > TODO_TOTAL then return false end

    local r, c = index_to_point(data, index)

    self._private.rows[r][c] = nil

    self:emit_signal("widget::layout_changed")

    return true
end

--- Remove one or more widgets from the layout
-- The last parameter can be a boolean, forcing a recursive seach of the
-- widget(s) to remove.
-- @param widget ... Widgets that should be removed (must at least be one)
-- @treturn boolean If the operation is successful
function grid:remove_widgets(...)
    local args = { ... }

    local recursive = type(args[#args]) == "boolean" and args[#args]

    local ret = true
    for k, rem_widget in ipairs(args) do
        if recursive and k == #args then break end

        local idx, l = self:index(rem_widget, recursive)

        if idx and l and l.remove then
            l:remove(idx, false)
        else
            ret = false
        end
    end

    return #args > (recursive and 1 or 0) and ret
end

function grid:get_children()
    --TODO
    return self._private.rows
end

function grid:set_children(children)
    self:reset()
    if #children > 0 then
        self:add(unpack(children))
    end
end

--- Replace the first instance of `widget` in the layout with `widget2`
-- @param widget The widget to replace
-- @param widget2 The widget to replace `widget` with
-- @tparam[opt=false] boolean recursive Digg in all compatible layouts to find the widget.
-- @treturn boolean If the operation is successful
function grid:replace_widget(widget, widget2, recursive)
    local idx, l = self:index(widget, recursive)

    if idx and l then
        l:set(idx, widget2)
        return true
    end

    return false
end

function grid:swap_widgets(widget1, widget2, recursive)
    base.check_widget(widget1)
    base.check_widget(widget2)

    local idx1, l1 = self:index(widget1, recursive)
    local idx2, l2 = self:index(widget2, recursive)

    if idx1 and l1 and idx2 and l2 and (l1.set or l1.set_widget) and (l2.set or l2.set_widget) then
        if l1.set then
            l1:set(idx1, widget2)
        elseif l1.set_widget then
            l1:set_widget(widget2)
        end
        if l2.set then
            l2:set(idx2, widget1)
        elseif l2.set_widget then
            l2:set_widget(widget1)
        end

        return true
    end

    return false
end

function grid:set(index, widget2)
    if (not widget2) or (not self._private.rows[index]) then return false end

    base.check_widget(widget2)

    self._private.rows[index] = widget2

    self:emit_signal("widget::layout_changed")

    return true
end

--- Insert a new widget in the layout at position `index`
-- @tparam number index The position
-- @param widget The widget
-- @treturn boolean If the operation is successful
function grid:insert(index, widget)
    local TODO_TOTAL = math.huge --FIXME
    if not index or index < 1 or index > TODO_TOTAL then return false end

    base.check_widget(widget)
    table.insert(self._private.rows, index, widget) --FIXME
    self:emit_signal("widget::layout_changed")

    return true
end

-- Fit the grid layout into the given space
-- @param context The context in which we are fit.
-- @param orig_width The available width.
-- @param orig_height The available height.
function grid:fit(context, orig_width, orig_height)
    local max_col, max_row = get_cell_sizes(self, context, orig_width, orig_height)

    -- Now that all fit is done, get the maximum
    local used_max_h, used_max_w = 0, 0

    for row_idx = 1, #max_row do
        -- The other widgets will be discarded
        if used_max_h + max_row[row_idx] > orig_height then
            break
        end

        used_max_h = used_max_h + max_row[row_idx]
    end

    for col_idx = 1, #max_col do
        -- The other widgets will be discarded
        if used_max_w + max_col[col_idx] > orig_width then
            break
        end

        used_max_w = used_max_w + max_col[col_idx]
    end

    return used_max_w, used_max_h
end

function grid:reset()
    self._private.rows = {}
    self:emit_signal("widget::layout_changed")
end

--- Set the layout's fill_space property. If this property is true, the last
-- widget will get all the space that is left. If this is false, the last widget
-- won't be handled specially and there can be space left unused.
-- @property fill_space

function grid:set_fill_space(val)
    if self._private.fill_space ~= val then
        self._private.fill_space = not not val
        self:emit_signal("widget::layout_changed")
    end
end

local function get_layout(dir, widget1, ...)
    local ret = base.make_widget(nil, nil, {enable_properties = true})

    util.table.crush(ret, grid, true)

    ret._private.widgets = {}
    ret:set_spacing(0)
    ret:set_fill_space(false)

    if widget1 then
        ret:add(widget1, ...)
    end

    return ret
end

--- Add spacing between each layout widgets
-- @property spacing
-- @tparam number spacing Spacing between widgets.

function grid:set_spacing(spacing)
    if self._private.spacing ~= spacing then
        self._private.spacing = spacing
        self:emit_signal("widget::layout_changed")
    end
end

function grid:get_spacing()
    return self._private.spacing or 0
end

--@DOC_widget_COMMON@

--@DOC_object_COMMON@

return setmetatable(grid, {__call=function(_, ...) return get_layout(...) end})

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
