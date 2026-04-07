function strip_quotes(s::String)
    s = strip(s)
    if (startswith(s, "\"") && endswith(s, "\"")) || (startswith(s, "'") && endswith(s, "'"))
        return s[2:end-1]
    end
    return s
end


function parse_fortran_logical(s::String)
    u = uppercase(strip(s))
    return u in (".TRUE.", "TRUE", "T")
end


function read_fortran_namelist_input(filename::String)
    text = read(filename, String)
    text = replace(text, r"!.*" => "")
    text = replace(text, '\n' => ' ')
    text = replace(text, "&INPUT" => "")
    text = replace(text, "/" => "")

    params = Dict{String, String}()
    for part in split(text, ',')
        if occursin("=", part)
            kv = split(part, "=", limit=2)
            params[strip(uppercase(kv[1]))] = strip(kv[2])
        end
    end
    return params
end