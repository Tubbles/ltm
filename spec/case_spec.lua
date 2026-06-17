local case = require("case")

describe("case: upper", function()
    it("uppercases ASCII letters", function()
        assert.are.equal("HELLO", case.upper("hello"))
        assert.are.equal("HELLO", case.upper("Hello"))
        assert.are.equal("HELLO", case.upper("HELLO"))
    end)

    it("leaves non-letters untouched", function()
        assert.are.equal("A1-B2 C3", case.upper("a1-b2 c3"))
    end)

    it("returns nil for empty input", function()
        assert.is_nil(case.upper(""))
    end)
end)

describe("case: lower", function()
    it("lowercases ASCII letters", function()
        assert.are.equal("hello", case.lower("HELLO"))
        assert.are.equal("hello", case.lower("Hello"))
        assert.are.equal("hello", case.lower("hello"))
    end)

    it("leaves non-letters untouched", function()
        assert.are.equal("a1-b2 c3", case.lower("A1-B2 C3"))
    end)

    it("returns nil for empty input", function()
        assert.is_nil(case.lower(""))
    end)
end)
