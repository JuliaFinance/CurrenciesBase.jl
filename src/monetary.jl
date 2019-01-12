#= Monetary type, and low-level operations =#

# Abstract class for Monetary-like things
"""
The abstract type of objects representing a single value in one currency, or a
collection of values in a set of currencies. These objects should behave like
`Monetary` or `Basket` objects.
"""
abstract type AbstractMonetary end

"""
A simpler variant of `Monetary` that is expected to eventually be the default.
The currency represented is part of the type and not the object. The value is
internally represented as a quantity of some number type. The usual way to
construct a `Currency` directly, if needed, is:

    Currency{:USD}(FixedDecimal{Int, 2}(1))  # 1.00 USD
"""
struct Currency{C, T} <: AbstractMonetary
    val::T

    (::Type{Currency{C}})(x::Real) where C = new{C,typeof(x)}(x)
end

"""
A representation of a monetary value, denominated in some currency. The currency
used is part of the type and not the object. The value is internally represented
as a quantity of some integer type. The usual way to construct a `Monetary`
directly, if needed, is:

    Monetary(:USD)      # 1.00 USD
    Monetary(:USD, 325) # 3.25 USD

Be careful about the decimal point, as the `Monetary` constructor takes an
integer, representing the number of smallest denominations of the currency.
Typically, this constructor is not called directly. It is easier to use the
`@usingcurrencies` macro and the `100USD` form instead.

Although this type is flexible enough to support values internally represented
as any integer type, such as `BigInt`, it is recommended to use the built-in
`Int` type on your architecture unless you need a bigger type. Do not mix
different kinds of internal types. To use a different internal representation,
change the type of the second argument to `Monetary`:

    Monetary(:USD, BigInt(100))

In some applications, the minor denomination of a currency is not precise
enough. It is sometimes useful to override the number of decimal points stored.
For these applications, a third type parameter can be provided, indicating the
number of decimal points to keep after the major denomination:

    Monetary{:USD, BigInt, 4}(10000)            # 1.0000 USD
    Monetary(:USD, BigInt(10000); precision=4)  # 1.0000 USD
"""
Monetary{C, I, f} = Currency{C, FixedDecimal{I, f}}

# TODO: deprecate this constructor
(::Type{Monetary{C, I, f}})(x::Integer) where {C, I, f} =
    Currency{C}(reinterpret(FixedDecimal{I,f}, x))
(::Type{Monetary{C, I, f}})(x::Real) where {C, I, f} =
    Currency{C}(FixedDecimal{I,f}(x))

function Monetary(T::Symbol, x; precision=decimals(T))
    if precision == -1
        throw(ArgumentError("Must provide precision for currency $T."))
    else
        Monetary{T, typeof(x), precision}(x)
    end
end

function Monetary(T::Symbol; precision=decimals(T), storage=Int)
    if precision == -1
        throw(ArgumentError("Must provide precision for currency $T."))
    else
        majorunit(Monetary{T, storage, precision})
    end
end

"""
    filltype(typ) → typ

Fill in default type parameters to get a fully-specified concrete type from a
partially-specified one.
"""
filltype(::Type{Monetary{T}}) where {T} = Monetary{T, Int, decimals(T)}
filltype(::Type{Monetary{T,U}}) where {T,U} = Monetary{T, U, decimals(T)}
