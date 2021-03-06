export read_xml_plist_string, read_xml_plist

using Dates
using Base64

function parse_obj(n::ElementNode)
    tag = nodename(n)

    if     "plist" == tag
        # Quick and dirty. We just try to get out data somehow
        # not caring too much about correctness of format.
        children = elements(n)
        if isempty(children)
            return nothing
        else
            parse_obj(first(children))
        end
    elseif "integer" == tag || "real" == tag
        Meta.parse(nodecontent(n))
    elseif "string" == tag
        nodecontent(n)
    elseif "true" == tag
        true
    elseif "false" == tag
        false
    elseif "date" == tag
        df = Dates.DateFormat("yyyy-mm-dd")
        # TODO: include time info
        date_string, time_string = split(nodecontent(n), 'T')
        return Date(date_string, df)
    elseif "data" == tag
        base64decode(nodecontent(n))
    elseif "array" == tag
        parse_array(n)
    elseif "dict" == tag
        parse_dict(n)
    end
end

function parse_array(parent::ElementNode)
    map(elements(parent)) do child
        parse_obj(child)
    end
end

function parse_dict(parent::ElementNode)
    dict =  Dict{Any, Any}()

    children = elements(parent)
    it = iterate(children)
    while it != nothing
        keynode, i = it
        if nodename(keynode) == "key"
            valuenode, i = iterate(children, i)
            dict[nodecontent(keynode)] = parse_obj(valuenode)
        else
            error("Expected XML node to be 'key' not '$(nodename(keynode))'")
        end
        it = iterate(children, i)
    end
    dict
end

function read_xml_plist_string(text::AbstractString)
    doc = parsexml(text)
    if hasroot(doc)
        parse_obj(root(doc))
    else
        nothing
    end
end

function read_xml_plist(stream::IO)
    text = read(stream, String)
    read_xml_plist_string(text)
end

function read_xml_plist(filename::AbstractString)
    open(read_xml_plist, filename)
end
