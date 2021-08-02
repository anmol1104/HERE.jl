using HTTP
using DataFrames

"""
    network(;apikey, bbox)

Returns shape for every street of the network within the bounding box.

# Arguments
apikey::String   : API key to access HERE
bbox::String     : Bounding box defined as `"lat₁,long₁;lat₂,long₂"`

For more information visit: https://developer.here.com/documentation/traffic/dev_guide/topics/guide.html

Example request: https://developer.here.com/documentation/traffic/dev_guide/topics_v6.1/example-flow-bounding-box.html
"""
function network(;apikey, bbox)
    # Request
    baseurl = "https://traffic.ls.hereapi.com"
    path = "traffic/6.2"
    resource = "flow.xml"
    url = "$baseurl/$path/$resource?apiKey=$apikey&bbox=$bbox&responseattributes=shape"
    r = HTTP.request(:GET, url)
    f = parsexml(String(r.body))
    rootNode = root(f)
    
    # Build network
    df = DataFrame(LID = Int64[], NAME = String[], LENGTH = Float64[], FFS = Float64[], SHAPE = String[])
    for node in iterate(rootNode)
        if nodename(node) == "FI"
            shape = ""
            for child in eachelement(node)
                # Fetch name and length
                if child == firstelement(node)
                    push!(df[!, :LID], length(df[!, :LID]) + 1)
                    push!(df[!, :NAME], child["DE"])
                    push!(df[!, :LENGTH], parse(Float64, child["LE"]))
                # Fetch free flow speed 
                elseif child == lastelement(node)
                    push!(df[!, :FFS], parse(Float64, child["FF"]))
                # Fetch link shape (Note: Link shape is of the same format as the bbox)
                else
                    shape *= replace(nodecontent(child), " " => ";")
                end
            end
            push!(df[!, :SHAPE], shape)
        end
    end

    return df
end