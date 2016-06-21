#=
A CPD is a Conditional Probability Distribution
In general, they represent distribtions of the form P(X|Y)
Each node in a Bayesian Network is associated with a variable,
and contains the CPD relating that var to its parents, P(x | parents(x))
=#

module CPDs

using Reexport
@reexport using Distributions
@reexport using DataFrames

import Iterators: product

export
    CPD,                           # the abstract CPD type

    Assignment,                    # variable assignment type, complete or partial, for a Bayesian Network
    NodeName,                      # variable name type

    StaticCPD,                     # static distribution (never uses parental information)
    CategoricalCPD,                # a table lookup based on discrete parental assignment
    LinearGaussianCPD,             # Normal with linear mean
    ConditionalLinearGaussianCPD,  # a LinearGaussianCPD lookup based on discrete parental assignment

    name,                          # obtain the name of the CPD
    parents,                       # obtain the parents in the CPD
    parentless,                    # whether the given variable is parentless
    disttype,                      # returns the CPD's distribution type
    nparams,                       # returns the number of free parameters required for the distribution

    # utils
    strip_arg,
    required_func,
    sub2ind_vec,
    infer_number_of_instantiations,
    consistent

#############################################

typealias NodeName Symbol
typealias Assignment Dict{Symbol, Any}

include("utils.jl")

#############################################

abstract CPD{D<:Distribution}

"""
    name(cpd::CPD)
Return the NodeName for the variable this CPD is defined for.
"""
@required_func name(cpd::CPD)

"""
    parents(cpd::CPD)
Return the parents for this CPD as a vector of NodeNames.
"""
@required_func parents(cpd::CPD)

"""
    cpd(a::Assignment)
Use the parental values in `a` to return the conditional distribution
"""
@required_func call(cpd::CPD, a::Assignment)

"""
    fit(::Type{CPD}, data::DataFrame, target::NodeName, parents::Vector{NodeName})
Construct a CPD for target by fitting it to the provided data
"""
@required_func Distributions.fit(cpdtype::Type{CPD}, data::DataFrame, target::NodeName, parents::Vector{NodeName})
@required_func Distributions.fit(cpdtype::Type{CPD}, data::DataFrame, target::NodeName)

"""
    nparams(cpd::CPD)
Return the number of free parameters that needed to be estimated for the CPD
"""
@required_func nparams(cpd::CPD)

"""
    parentless(cpd::CPD)
Return whether this CPD has parents.
"""
parentless(cpd::CPD) = isempty(parents(cpd))

"""
    disttype(cpd::CPD)
Return the type of the CPD's distribution
"""
disttype{D}(cpd::CPD{D}) = D

"""
    rand(cpd::CPD)
Condition and then draw from the distribution
"""
Base.rand(cpd::CPD, a::Assignment) = rand(cpd(a))

"""
    pdf(cpd::CPD)
Condition and then return the pdf
"""
Distributions.pdf(cpd::CPD, a::Assignment) = pdf(cpd(a), a[name(cpd)])

"""
    logpdf(cpd::CPD)
Condition and then return the logpdf
"""
Distributions.logpdf(cpd::CPD, a::Assignment) = logpdf(cpd(a), a[name(cpd)])

"""
    logpdf(cpd::CPD, data::DataFrame)
Return the logpdf across the dataset
"""
function Distributions.logpdf(cpd::CPD, data::DataFrame)
    retval = 0.0
    a = Assignment()
    for i in 1 : nrow(data)
        get!(a, cpd, data, i)
        retval += logpdf(cpd, a)
    end
    retval
end

"""
    pdf(cpd::CPD, data::DataFrame)
Return the pdf across the dataset
"""
Distributions.pdf(cpd::CPD, data::DataFrame) = exp(logpdf(cpd, data))

Base.eltype{D}(cpd::CPD{D}) = eltype(D)

###########################

"""
    get!(a::Assignment, b::Assignment)
Modify and return the assignment to contain the ith entry
"""
function Base.get!(a::Assignment, cpd::CPD, data::DataFrame, i::Int)
    target = name(cpd)
    a[target] = data[i,target]
    for j in parents(cpd)
        a[j] = data[i,j]
    end
    a
end

###########################

include("static_cpd.jl")
include("categorical_cpd.jl")
include("linear_gaussian_cpd.jl")
include("conditional_linear_gaussian_cpd.jl")

end # module CPDs
