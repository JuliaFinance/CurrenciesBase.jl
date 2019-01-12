#= Currency info lookup functions =#

# Macro to define flexible lookup functions that accept type or Monetary object.
macro flexible(assignment)
    @assert assignment.head == :(=)
    symb = assignment.args[1].args[1]
    quote
        $(esc(assignment))
        $(esc(symb))(::Type{U}) where U <: Monetary{S} where S = $(esc(symb))(S)
        $(esc(symb))(m::Monetary) = $(esc(symb))(typeof(m))
    end
end

"""
    currency(m::Monetary) → Symbol

Return a symbol corresponding to the ISO 4217 currency code of the currency that
the given monetary amount is representing. For example, `currency(80USD)` will
return `:USD`. If the given monetary value is of a non-ISO 4217 currency, then
the returned symbol should contain only lowercase letters.

Prefer `iso4217alpha` to this function if a string is desired.
"""
currency(::Monetary{T}) where {T} = T

"""
    decimals(m::Monetary) → Int
    decimals(s::Symbol)   → Int
    decimals(d::DataType) → Int

Get the precision, in terms of the number of decimal places after the major
currency unit, of the given `Monetary` value or type. Alternatively, if given a
symbol, gets the default exponent (the number of decimal places to represent the
minor currency unit) for that symbol. Return `-1` if there is no sane minor
unit, such as for several kinds of precious metal.
"""
decimals(c::Symbol) = ISO4217[c][1]
decimals(::Monetary{T,U,V}) where {T,U,V} = V
decimals(::Type{Monetary{T,U,V}}) where {T,U,V} = V
decimals(::Type{T}) where {T<:Monetary} = decimals(filltype(T))

"""
Get a brief human-readable English-language description of the currency. The
description should begin with the common name of the currency, which should
describe it unambiguously (up to variations on the same currency). Optionally,
parentheses following the main description may include additional information
(such as the unit of a major currency unit).

This function may be called with either a symbol, a `Monetary` type, or a
`Monetary` object.
"""
function currencyinfo end
@flexible currencyinfo(s::Symbol) = ISO4217[s][2]

"""
    iso4217num(s::Symbol)   → Int
    iso4217num(m::Monetary) → Int
    iso4217num(t::DataType) → Int

Get the ISO 4217 numeric code for a currency. For custom currencies, a value of
`0` will be returned. This function may be called with either a symbol, a
`Monetary` type, or a `Monetary` object. Note that most applications should
zero-pad this code to three digits.
"""
function iso4217num end
@flexible iso4217num(s::Symbol) = ISO4217[s][3]


"""
    iso4217alpha(s::Symbol)   → String
    iso4217alpha(m::Monetary) → String
    iso4217alpha(t::DataType) → String

Get the ISO 4217 alphabetic code for a currency. For custom currencies, a
lowercase string will be returned, and this should not be interpreted as an ISO
4217 code. Otherwise, a three-letter uppercase string will be returned. This
function may be called with either a symbol, a `Monetary` type, or a `Monetary`
object.
"""
function iso4217alpha end
@flexible iso4217alpha(s::Symbol) = string(s) |> String


"""
    shortsymbol(s::Symbol)   → String
    shortsymbol(m::Monetary) → String
    shortsymbol(t::DataType) → String

Get a short, possibly ambiguous, commonly-used symbol for a currency. This
function may be called with either a symbol, a `Monetary` type, or a `Monetary`
object.
"""
function shortsymbol end
@flexible shortsymbol(s::Symbol) = get(SHORT_SYMBOL, s, iso4217alpha(s))


"""
    longsymbol(s::Symbol)   → String
    longsymbol(m::Monetary) → String
    longsymbol(t::DataType) → String

Get a commonly-used currency symbol for a currency, with at least enough
disambiguation to be non-ambiguous. This function may be called with either a
symbol, a `Monetary` type, or a `Monetary` object.
"""
function longsymbol end
@flexible longsymbol(s::Symbol) = get(LONG_SYMBOL, s, iso4217alpha(s))

"""
    majorunit(s::Symbol)   → Monetary{s}
    majorunit(m::Monetary) → typeof(m)
    majorunit(t::DataType) → t

Get the major unit of the currency. This function may be called with either a
symbol, a `Monetary` type, or a `Monetary` object.
"""
function majorunit end
majorunit(s::Symbol) = majorunit(Monetary{s})
majorunit(::Type{Monetary{T,U,V}}) where {T,U,V} = Monetary{T,U,V}(convert(U, 10)^V)
majorunit(::Type{T}) where {T<:Monetary} = majorunit(filltype(T))
majorunit(x::Monetary) = majorunit(typeof(x))
