type FunctionalCPD{D} <: CPD{D}
    target::NodeName
    parents::NodeNames
    accessor::Function # calling this gives you the distribution from the assignment

    FunctionalCPD(target::NodeName, accessor::Function) = new(target, NodeName[], accessor)
    FunctionalCPD(target::NodeName, parents::NodeNames, accessor::Function) = new(target, parents, accessor)
end


name(cpd::FunctionalCPD) = cpd.target
parents(cpd::FunctionalCPD) = cpd.parents
@compat (cpd::FunctionalCPD)(a::Assignment) = cpd.accessor(a)
@compat (cpd::FunctionalCPD)() = (cpd)(Assignment()) # cpd()
@compat (cpd::FunctionalCPD)(pair::Pair{NodeName}...) = (cpd)(Assignment(pair)) # cpd(:A=>1)