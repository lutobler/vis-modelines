require 'busted.runner'()
local m = require("vis-modelines")

local function file_to_table(fname)
    local lines = {}
    local f = io.open(fname, "r")
    for line in f:lines() do
        if line then lines[#lines + 1] = line end
    end
    f:close()
    return lines
end

describe("Modeline parser", function()
    local files = {
        {
            "tests/file1.in",
            nil,
            nil,
            { }
        },
        {
            "tests/file2.in",
            "# vi:noai:sw=3 ts=6",
            { "noai", { "sw", "3" }, { "ts", "6" } },
            { "set ai off", "set tw 3" }
        },
        {
            "tests/file3.in",
            "-- vim: tw=77",
            { { "tw", "77" } },
            { }
        },
        {
            "tests/file4.in",
            "/* vim: set ai tw=75: */",
            { "ai", { "tw", "75" } },
            { "set ai on" }
        },
        {
            "tests/file5.in",
            "/* Vim: set ai tw=75 */",
            { "ai", { "tw", "75" } },
            { "set ai on" }
        },
        {
            "tests/file6.in",
            "/* vim700: set foldmethod=marker */",
            { { "foldmethod", "marker" } },
            { }
        },
        {
            "tests/file7.in",
            "/* vim>702: set cole=2: */",
            { { "cole", "2" } },
            { }
        },
        {
            "tests/file8.in",
            "// vim: noai:sw=8:ts=4",
            { "noai", { "sw", "8" }, { "ts", "4" } },
            { "set ai off", "set tw 8" }
        },
        {
            "tests/file9.in",
            "-- Vim: ft=lua",
            { { "ft", "lua" } },
            { "set syntax lua" }
        }
    }

    it("should correctly detect modelines in files", function()
        assert.is_true(m.find_modeline(file_to_table(files[1][1])) == files[1][2])
        assert.is_true(m.find_modeline(file_to_table(files[2][1])) == files[2][2])
        assert.is_true(m.find_modeline(file_to_table(files[3][1])) == files[3][2])
        assert.is_true(m.find_modeline(file_to_table(files[4][1])) == files[4][2])
        assert.is_true(m.find_modeline(file_to_table(files[5][1])) == files[5][2])
        assert.is_true(m.find_modeline(file_to_table(files[6][1])) == files[6][2])
        assert.is_true(m.find_modeline(file_to_table(files[7][1])) == files[7][2])
        assert.is_true(m.find_modeline(file_to_table(files[8][1])) == files[8][2])
        assert.is_true(m.find_modeline(file_to_table(files[9][1])) == files[9][2])
    end)

    it("should parse modelines correctly", function()
        local function parse(i)
            local ml = m.find_modeline(file_to_table(files[i][1]))
            if not ml then return nil end
            return m.parse_modeline(ml)
        end
        assert.are.same(parse(1), files[1][3])
        assert.are.same(parse(2), files[2][3])
        assert.are.same(parse(3), files[3][3])
        assert.are.same(parse(4), files[4][3])
        assert.are.same(parse(5), files[5][3])
        assert.are.same(parse(6), files[6][3])
        assert.are.same(parse(7), files[7][3])
        assert.are.same(parse(8), files[8][3])
        assert.are.same(parse(9), files[9][3])
    end)

    it("should map the right options for vis", function()
        local function map(i)
            local ml = m.find_modeline(file_to_table(files[i][1]))
            if not ml then return { } end
            return m.map_options(ml)
        end
        assert.are.same(map(1), files[1][4])
        assert.are.same(map(2), files[2][4])
        assert.are.same(map(3), files[3][4])
        assert.are.same(map(4), files[4][4])
        assert.are.same(map(5), files[5][4])
        assert.are.same(map(6), files[6][4])
        assert.are.same(map(7), files[7][4])
        assert.are.same(map(8), files[8][4])
        assert.are.same(map(9), files[9][4])
    end)
end)
