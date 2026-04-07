function write_1d(filename::String, arr)
    open(filename, "w") do io
        for val in arr
            println(io, val)
        end
    end
end


function write_2d_slices(filename::String, arr, mt::Int, nf_tf::Int)
    open(filename, "w") do io
        for l in 1:nf_tf
            println(io, join((string(arr[i, l]) for i in 1:mt), " "))
        end
    end
end