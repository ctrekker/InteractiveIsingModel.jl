using PackageCompiler
PackageCompiler.create_sysimage(["GLMakie"]; sysimage_path="ising.so", precompile_statements_file="ising.trace.jl")