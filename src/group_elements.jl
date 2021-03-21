################################################################################
#
#   group_elements.jl : Interface for group elements
#
################################################################################
# Obligatory methods
################################################################################

@doc Markdown.doc"""
    parent(g::GroupElement)

Return the parent of the group element.
"""
Base.parent(g::GroupElement) =
    throw(InterfaceNotImplemented(:Group, "Base.parent(::$(typeof(g)))"))

@doc Markdown.doc"""
    parent_type(::Type{<:GroupElement})
    parent_type(g::GroupElement)

Return the type of parent of the group element $g$.
"""
parent_type(::Type{G}) where {G <: GroupElement} =
    throw(InterfaceNotImplemented(
        :Group,
        "GroupsCore.parent_type(::Type{$G})"
       ))
parent_type(g::GroupElement) = parent_type(typeof(g))

@doc Markdown.doc"""
    ==(g::G, h::G) where {G <: GroupElement}

Return `true` if and only if the mathematical equality $g = h$ holds.

!!! note

    This function may not return, due to unsolvable word problem.
"""
Base.:(==)(g::G, h::G) where {G <: GroupElement} = throw(
    InterfaceNotImplemented(:Group, "Base.:(==)(::$G, ::$G)"),
)

@doc Markdown.doc"""
    isfiniteorder(g::GroupElement)

Return `true` if $g$ is of finite order, possibly without computing it.
"""
function isfiniteorder(g::GroupElement)
    isfinite(parent(g)) && return true
    throw(
        InterfaceNotImplemented(:Group, "GroupsCore.isfiniteorder(::$(typeof(g)))"),
    )
end

Base.deepcopy_internal(g::GroupElement, stackdict::IdDict) = throw(
    InterfaceNotImplemented(
        :Group,
        "Base.deepcopy_internal(::$(typeof(g)), ::IdDict)",
    ),
)
# TODO: Technically, it is not necessary to implement `deepcopy_internal` method
# if `parent(g)` can be reconstructed exactly from `g` (i.e. either it's cached,
# or a singleton). However by defining this fallback we force everybody to
# implement it, except isbits group elements.

@doc Markdown.doc"""
    inv(g::GroupElement)

Return $g^{-1}$, the group inverse.
"""
Base.inv(g::GroupElement) =
    throw(InterfaceNotImplemented(:Group, "Base.inv(::$(typeof(g)))"))

@doc Markdown.doc"""
    *(g::G, h::G) where {G <: GroupElement}

Return $g h$, the result of group binary operation.
"""
Base.:(*)(g::G, h::G) where {G <: GroupElement} = throw(
    InterfaceNotImplemented(
        :Group,
        "Base.:(*)(::$(typeof(g)), ::$(typeof(g)))",
    ),
)

################################################################################
# Default implementations
################################################################################

@doc Markdown.doc"""
    one(g::GroupElement)

Return the identity element in the group of $g$.
"""
Base.one(g::GroupElement) = one(parent(g))

@doc Markdown.doc"""
    order(::Type{I} = BigInt, g::GroupElement) where {I <: Integer}

Return the order of $g$ as an instance of `I`. If $g$ is of infinite order
`GroupsCore.InfiniteOrder` exception will be thrown.

!!! warning

    Only arbitrary sized integers are required to return a mathematically
    correct answer.
"""
function order(::Type{I}, g::GroupElement) where {I<:Integer}
    isfiniteorder(g) || throw(InfiniteOrder(g))
    isone(g) && return I(1)
    o = I(1)
    gg = deepcopy(g)
    out = similar(g)
    while !isone(gg)
        o += I(1)
        gg = mul!(out, gg, g)
    end
    return o
end
order(g::GroupElement) = order(BigInt, g)

@doc Markdown.doc"""
    conj(g::G, h::G) where {G <: GroupElement}

Return conjugation of $g$ by $h$, i.e. $h^{-1} g h$.
"""
Base.conj(g::G, h::G) where {G <: GroupElement} = conj!(similar(g), g, h)

@doc Markdown.doc"""
    ^(g::G, h::G) where {G <: GroupElement}

Alias for [`conj`](@ref GroupsCore.conj).
"""
Base.:(^)(g::G, h::G) where {G <: GroupElement} = conj(g, h)

@doc Markdown.doc"""
    comm(g::G, h::G, k::G...) where {G <: GroupElement}

Return the left associative iterated commutator $[[g, h], ...]$, where
$[g, h] = g^{-1} h^{-1} g h$.
"""
function comm(g::G, h::G, k::G...) where {G <: GroupElement}
    res = comm!(similar(g), g, h)
    for l in k
        res = comm!(res, res, l)
    end
    return res
end

Base.literal_pow(::typeof(^), g::GroupElement, ::Val{-1}) = inv(g)

Base.:(/)(g::G, h::G) where {G <: GroupElement} = div_right!(similar(g), g, h)

################################################################################
# Default implementations that (might) need performance modification
################################################################################

@doc Markdown.doc"""
    similar(g::GroupElement)

Return a group element sharing the parent with $g$. Might be arbitrary and
possibly uninitialized.
"""
Base.similar(g::GroupElement) = one(g)

@doc Markdown.doc"""
    isone(g::GroupElement)

Return true if $g$ is the identity element.
"""
Base.isone(g::GroupElement) = g == one(g)

@doc Markdown.doc"""
    isequal(g::G, h::G) where {G <: GroupElement}

Return the "best effort" equality for group elements.

The implication `isequal(g, h)` → $g = h$, must be always satisfied, i.e.
`isequal(g, h)` might return `false` even if `g == h` holds (i.e. $g$ and $h$
are mathematically equal).

For example, in a finitely presented group, `isequal` may return the equality
of words.
"""
Base.isequal(g::G, h::G) where {G <: GroupElement} = g == h

function Base.:^(g::GroupElement, n::Integer)
    n == 0 && return one(g)
    n < 0 && return inv(g)^-n
    return Base.power_by_squaring(g, n)
end

# NOTE: Modification RECOMMENDED for performance reasons
Base.hash(g::GroupElement, h::UInt) = hash(typeof(g), h)

################################################################################
# Mutable API where modifications are recommended for performance reasons
################################################################################

@doc Markdown.doc"""
    one!(g::GroupElement)

Return `one(g)`, possibly modifying `g`.
"""
one!(g::GroupElement) = one(parent(g))

@doc Markdown.doc"""
    inv!(out::G, g::G) where {G <: GroupElement}

Return `inv(g)`, possibly modifying `out`. Aliasing of `g` with `out` is
allowed.
"""
inv!(out::G, g::G) where {G <: GroupElement} = inv(g)

@doc Markdown.doc"""
    mul!(out::G, g::G, h::G) where {G <: GroupElement}

Return $g h$, possibly modifying `out`. Aliasing of `g` or `h` with `out` is
allowed.
"""
mul!(out::G, g::G, h::G) where {G <: GroupElement} = g * h

@doc Markdown.doc"""
    div_right!(out::G, g::G, h::G) where {G <: GroupElement}

Return $g h^{-1}$, possibly modifying `out`. Aliasing of `g` or `h` with `out`
is allowed.
"""
div_right!(out::G, g::G, h::G) where {G <: GroupElement} = mul!(out, g, inv(h))

@doc Markdown.doc"""
    div_left!(out::G, g::G, h::G) where {G <: GroupElement}

Return $h^{-1} g$, possibly modifying `out`. Aliasing of `g` or `h` with `out`
is allowed.
"""
function div_left!(out::G, g::G, h::G) where {G <: GroupElement}
    out = (out === g || out === h) ? inv(h) : inv!(out, h)
    return mul!(out, out, g)
end

@doc Markdown.doc"""
    conj!(out::G, g::G, h::G) where {G <: GroupElement}

Return $h^{-1} g h$, `possibly modifying `out`. Aliasing of `g` or `h` with
`out` is allowed.
"""
function conj!(out::G, g::G, h::G) where {G <: GroupElement}
    out = (out === g || out === h) ? inv(h) : inv!(out, h)
    out = mul!(out, out, g)
    return mul!(out, out, h)
end

@doc Markdown.doc"""
    comm!(out::G, g::G, h::G) where {G <: GroupElement}

Return $g^{-1} h^{-1} g h$, possibly modifying `out`. Aliasing of `g` or `h`
with `out` is allowed.
"""
function comm!(out::G, g::G, h::G) where {G <: GroupElement}
    # TODO: can we make comm! with 3 arguments without allocation??
    out = conj!(out, g, h)
    return div_left!(out, out, g)
end
