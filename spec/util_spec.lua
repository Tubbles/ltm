local util = require("lib.util")

describe("util.flatten", function()
    it("copies keys from source into target", function()
        local target = {}
        util.flatten(target, {a = 1, b = 2})
        assert.are.equal(1, target.a)
        assert.are.equal(2, target.b)
    end)

    it("returns the target table", function()
        local target = {}
        local result = util.flatten(target, {a = 1})
        assert.are.equal(target, result)
    end)

    it("raises on name collision", function()
        local target = {x = "first"}
        assert.has_error(function()
            util.flatten(target, {x = "second"})
        end)
    end)

    it("collision error mentions the colliding key", function()
        local target = {pi = 3}
        local ok, err = pcall(util.flatten, target, {pi = 3.14})
        assert.is_false(ok)
        assert.is_truthy(err:find("pi"))
    end)
end)

describe("util.nonempty", function()
    it("splits on newline and keeps non-blank lines", function()
        assert.are.same({"a", "b", "c"}, util.nonempty("a\nb\nc"))
    end)

    it("drops whitespace-only lines", function()
        assert.are.same({"a", "b"}, util.nonempty("a\n\nb"))
    end)

    it("drops lines that are only spaces and tabs", function()
        assert.are.same({"x"}, util.nonempty("x\n   \n\t\t\n"))
    end)

    it("returns empty array for entirely blank input", function()
        assert.are.same({}, util.nonempty(""))
        assert.are.same({}, util.nonempty("\n\n\n"))
        assert.are.same({}, util.nonempty("   "))
    end)

    it("preserves the input even without a trailing newline", function()
        assert.are.same({"abc"}, util.nonempty("abc"))
    end)
end)

describe("util.strip_prefix", function()
    it("strips 0x for hex base", function()
        assert.are.equal("ff", util.strip_prefix("0xff", 16))
        assert.are.equal("ff", util.strip_prefix("0Xff", 16))
        assert.are.equal("FF", util.strip_prefix("0xFF", 16))
    end)

    it("strips 0o for oct base", function()
        assert.are.equal("77", util.strip_prefix("0o77", 8))
        assert.are.equal("77", util.strip_prefix("0O77", 8))
    end)

    it("strips 0b for bin base", function()
        assert.are.equal("101", util.strip_prefix("0b101", 2))
        assert.are.equal("101", util.strip_prefix("0B101", 2))
    end)

    it("does not strip a mismatched prefix", function()
        assert.are.equal("0bff", util.strip_prefix("0bff", 16))
        assert.are.equal("0xff", util.strip_prefix("0xff", 2))
        assert.are.equal("0o77", util.strip_prefix("0o77", 10))
        assert.are.equal("0x10", util.strip_prefix("0x10", 10))
    end)

    it("preserves sign before the prefix", function()
        assert.are.equal("-ff", util.strip_prefix("-0xff", 16))
        assert.are.equal("+ff", util.strip_prefix("+0xff", 16))
        assert.are.equal("-101", util.strip_prefix("-0b101", 2))
    end)

    it("passes through unprefixed strings", function()
        assert.are.equal("ff", util.strip_prefix("ff", 16))
        assert.are.equal("123", util.strip_prefix("123", 10))
        assert.are.equal("-1", util.strip_prefix("-1", 10))
    end)

    it("returns the input unchanged for bases with no prefix entry", function()
        assert.are.equal("abc", util.strip_prefix("abc", 36))
        assert.are.equal("123", util.strip_prefix("123", 10))
    end)
end)

describe("util.pad_width", function()
    it("returns the longest string length", function()
        assert.are.equal(3, util.pad_width({"a", "bb", "ccc"}))
        assert.are.equal(5, util.pad_width({"hello", "hi"}))
    end)

    it("returns zero for an empty array", function()
        assert.are.equal(0, util.pad_width({}))
    end)

    it("counts bytes including sign characters", function()
        assert.are.equal(3, util.pad_width({"-1", "10", "100"}))
    end)
end)

describe("util.zero_pad", function()
    it("pads positive numbers with leading zeros", function()
        assert.are.equal("007", util.zero_pad("7", 3))
    end)

    it("pads negative numbers with zeros after the sign", function()
        assert.are.equal("-01", util.zero_pad("-1", 3))
        assert.are.equal("-007", util.zero_pad("-7", 4))
    end)

    it("preserves explicit plus sign", function()
        assert.are.equal("+01", util.zero_pad("+1", 3))
    end)

    it("does not shrink strings that are already at or over width", function()
        assert.are.equal("123", util.zero_pad("123", 2))
        assert.are.equal("123", util.zero_pad("123", 3))
    end)
end)

describe("util.space_pad", function()
    it("left-pads with spaces", function()
        assert.are.equal("  7", util.space_pad("7", 3))
        assert.are.equal(" -1", util.space_pad("-1", 3))
    end)

    it("does not shrink strings that are already at or over width", function()
        assert.are.equal("123", util.space_pad("123", 2))
        assert.are.equal("123", util.space_pad("123", 3))
    end)
end)
