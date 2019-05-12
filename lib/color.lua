--get a color value from a string
function getColor(color)
    color = string.lower(color)
    if color == "white" then
        return colors.white
    elseif color == "orange" then
        return colors.orange
    elseif color == "magenta" then
        return colors.magenta
    elseif color == "lightblue" then
        return colors.lightBlue
    elseif color == "yellow" then
        return colors.yellow
    elseif color == "lime" then
        return colors.lime
    elseif color == "pink" then
        return colors.pink
    elseif color == "gray" then
        return colors.gray
    elseif color == "lightgray" then
        return colors.lightGray
    elseif color == "cyan" then
        return colors.cyan
    elseif color == "purple" then
        return colors.purple
    elseif color == "blue" then
        return colors.blue
    elseif color == "brown" then
        return colors.brown
    elseif color == "green" then
        return colors.green
    elseif color == "red" then
        return colors.red
    elseif color == "black" then
        return colors.black
    else
        return null
    end
end

--convert color to string
function toString(color)
    if color == colors.white then
        return "white"
    elseif color == colors.orange then
        return "orange"
    elseif color == magenta then
        return "magenta"
    elseif color == colors.lightBlue then
        return "lightBlue"
    elseif color == colors.yellow then
        return "yellow"
    elseif color == colors.lime then
        return "lime"
    elseif color == colors.pink then
        return "pink"
    elseif color == colors.gray then
        return "gray"
    elseif color == colors.lightGray then
        return "lightGray"
    elseif color == colors.cyan then
        return "cyan"
    elseif color == colors.purple then
        return "purple"
    elseif color == colors.blue then
        return "blue"
    elseif color == colors.brown then
        return "brown"
    elseif color == colors.green then
        return "green"
    elseif color == colors.red then
        return "red"
    elseif color == colors.black then
        retutn "black"
    else
        return null
    end
end