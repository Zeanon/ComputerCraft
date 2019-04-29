-- formatting

function format_int(number)

	if number == nil then number = 0 end

  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")

  -- reverse the int-string back remove an optional comma and put the
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function getInteger(number)
    if 0 <= number and number < 1 then
        return 0
    end
    if 1 <= number and number < 2 then
        return 1
    elseif 2 <= number and number < 3 then
        return 2
    elseif 3 <= number and number < 4 then
        return 3
    elseif 4 <= number and number < 5 then
        return 4
    elseif 5 <= number and number < 6 then
        return 5
    elseif 6 <= number and number < 7 then
        return 6
    elseif 7 <= number and number < 8 then
        return 7
    elseif 8 <= number and number < 2 then
        return 8
    elseif 9 <= number and number < 10 then
        return 9
    end
end

-- monitor related

--display text text on monitor, "mon" peripheral
function draw_text(mon, x, y, text, text_color, bg_color)
    mon.monitor.setBackgroundColor(bg_color)
    mon.monitor.setTextColor(text_color)
    mon.monitor.setCursorPos(x,y)
    mon.monitor.write(text)
end

function draw_text_right(mon, offset, y, text, text_color, bg_color)
    mon.monitor.setBackgroundColor(bg_color)
    mon.monitor.setTextColor(text_color)
    mon.monitor.setCursorPos(mon.X-string.len(tostring(text))-offset,y)
    mon.monitor.write(text)
end

function draw_text_lr(mon, x, y, offset, text1, text2, text1_color, text2_color, bg_color)
	draw_text(mon, x, y, text1, text1_color, bg_color)
	draw_text_right(mon, offset, y, text2, text2_color, bg_color)
end

--draw line on computer terminal
function draw_line(mon, x, y, length, color)
    if length < 0 then
      length = 0
    end
    mon.monitor.setBackgroundColor(color)
    mon.monitor.setCursorPos(x,y)
    mon.monitor.write(string.rep(" ", length))
end

--draw vertical line
function draw_column(mon, x, y, height, color)
    if height < 0 then
        height = 0
    end
    mon.monitor.setBackgroundColor(color)
    local i = 1
    while i <= height do
        mon.monitor.setCursorPos(x,y)
        mon.monitor.write(" ")
        y = y + 1
        i = i + 1
    end
end

--create progress bar
--draws two overlapping lines
--background line of bg_color
--main line of bar_color as a percentage of minVal/maxVal
function progress_bar(mon, x, y, length, minVal, maxVal, bar_color, bg_color)
    draw_line(mon, x, y, length, bg_color) --backgoround bar
    local barSize = math.floor((minVal/maxVal) * length)
    draw_line(mon, x, y, barSize, bar_color) --progress so far
end

function draw_0(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_column(mon, x, y, 5, color)
    draw_column(mon, x+2, y, 5, color)
    mon.monitor.setCursorPos(x+1,y)
    mon.monitor.write(" ")
    mon.monitor.setCursorPos(x+1,y+4)
    mon.monitor.write(" ")

end

function draw_1(mon, x, y, color)
    draw_column(mon, x+2, y, 5, color)
end

function draw_2(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_line(mon, x, y, 3, color)
    draw_line(mon, x, y+2, 3, color)
    draw_line(mon, x, y+4, 3, color)
    mon.monitor.setCursorPos(x+2,y+1)
    mon.monitor.write(" ")
    mon.monitor.setCursorPos(x,y+3)
    mon.monitor.write(" ")
end

function draw_3(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_line(mon, x, y, 3, color)
    draw_line(mon, x, y+2, 3, color)
    draw_line(mon, x, y+4, 3, color)
    mon.monitor.setCursorPos(x+2,y+1)
    mon.monitor.write(" ")
    mon.monitor.setCursorPos(x+2,y+3)
    mon.monitor.write(" ")
end

function draw_4(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_column(mon, x, y, 3, color)
    draw_column(mon, x+2, y, 5, color)
    mon.monitor.setCursorPos(x+1,y+2)
    mon.monitor.write(" ")
end

function draw_5(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_line(mon, x, y, 3, color)
    draw_line(mon, x, y+2, 3, color)
    draw_line(mon, x, y+4, 3, color)
    mon.monitor.setCursorPos(x,y+1)
    mon.monitor.write(" ")
    mon.monitor.setCursorPos(x+2,y+3)
    mon.monitor.write(" ")
end

function draw_6(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_5(mon, x, y, color)
    mon.monitor.setCursorPos(x,y+3)
    mon.monitor.write(" ")
end

function draw_7(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_column(mon, x+2, y, 5, color)
    mon.monitor.setCursorPos(x,y)
    mon.monitor.write("  ")
end

function draw_8(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_0(mon, x, y, color)
    mon.monitor.setCursorPos(x+1,y+2)
    mon.monitor.write(" ")
end

function draw_9(mon, x, y, color)
    mon.monitor.setBackgroundColor(color)
    draw_5(mon, x, y, color)
    mon.monitor.setCursorPos(x+2,y+1)
    mon.monitor.write(" ")
end

function draw_number(number, divider, mon, x, y, color)
    if gui.getInteger(number / divider) == 1 then
        gui.draw_1(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 2 then
        gui.draw_2(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 3 then
        gui.draw_3(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 4 then
        gui.draw_4(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 5 then
        gui.draw_5(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 6 then
        gui.draw_6(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 7 then
        gui.draw_7(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 8 then
        gui.draw_8(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 9 then
        gui.draw_9(mon, x, y, color)
    elseif gui.getInteger(number / divider) == 0 and gui.getInteger(number / divider * 10) ~= 0 then
        gui.draw_0(mon, x, y, color)
    end
end

function clear(mon)
    term.clear()
    term.setCursorPos(1,1)
    mon.monitor.setBackgroundColor(colors.black)
    mon.monitor.clear()
    mon.monitor.setCursorPos(1,1)
end
