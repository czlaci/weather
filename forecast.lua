# coding:utf8

bg_corner=10
bg_colour=0x222222
border_colour=0xaaaaaa
bg_alpha=0.5

cr_font='GE Inspira'

cr_black=0x000000
cr_blue=0x6699ff
cr_red=0xff5555
cr_green=0x44ee44
cr_yellow=0xeeee44
cr_text2=0xeeaa44
cr_text1=0xeecc88
cr_text=0xeeeecc
cr_icon=0xffeeaa
cr_white=0xffffff
cr_shadow=0x000000
cr_dew=0x4466bb


require 'cairo'

function rgb_to_r_g_b(colour,alpha)
	return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

local bytemarkers = { {0x7FF,192}, {0xFFFF,224}, {0x1FFFFF,240} }

function utf8(decimal)
    if decimal<128 then return string.char(decimal) end
    local charbytes = {}
    for bytes,vals in ipairs(bytemarkers) do
      if decimal<=vals[1] then
        for b=bytes+1,2,-1 do
          local mod = decimal%64
          decimal = (decimal-mod)/64
          charbytes[b] = string.char(128+mod)
        end
        charbytes[1] = string.char(vals[2]+decimal)
        break
      end
    end
    return table.concat(charbytes)
end

function print_text(cr, x, y, t, o, text)
    cairo_select_font_face(cr, cr_font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    if t == 3 then
	cairo_select_font_face(cr, cr_font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
	cairo_set_font_size(cr, 22)
    elseif t == 2 then
	cairo_select_font_face(cr, cr_font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
	cairo_set_font_size(cr, 15)
    elseif t == 1 then
	cairo_set_font_size(cr, 13)
    else
	cairo_set_font_size(cr, 15)
    end
    cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_shadow, 0.2))
    if o == 2 then
	local ext = cairo_text_extents_t:create()
	cairo_text_extents(cr, text, ext)
	x = x - ext.width
    elseif o == 1 then
	local ext = cairo_text_extents_t:create()
	cairo_text_extents(cr, text, ext)
	x = x - (ext.width/2)
    end
    cairo_move_to(cr, x+1, y+1)
    cairo_show_text(cr, text)

    if t == 3 then
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_text2, 1.0))
    elseif t == 2 then
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_text2, 1.0))
    elseif t == 1 then
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_text1, 1.0))
    else
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_text, 1.0))
    end
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
end

function print_icon(cr, x, y, text)
    cairo_select_font_face(cr, 'GE Inspira', CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 26)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_icon, 1.0))
    cairo_move_to(cr, x, y+4)
    cairo_show_text(cr, text)
end

function print_temp(cr, x, y, n, temp)
    cairo_select_font_face(cr, cr_font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    if n == 1 then
	cairo_set_font_size(cr, 28)
    else
	cairo_set_font_size(cr, 22)
    end
    cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_shadow, 0.3))
    cairo_move_to(cr, x+1, y+1)
    cairo_show_text(cr, string.format("%3d°", temp))
    if temp >= 28 then
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_red, 1.0))
    elseif temp >= 18 then
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_green, 1.0))
    elseif temp >= 0 then
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_yellow, 1.0))
    else
	cairo_set_source_rgba(cr, rgb_to_r_g_b(cr_blue, 1.0))
    end
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, string.format("%3d°", temp))
end

function print_icons(cr, x, y, n, name)
    cairo_save(cr)
    cairo_translate(cr, x, y)
    code = string.format("/home/laci/.conky/icons/%s.png", name)
    local img=cairo_image_surface_create_from_png(code)
    cairo_scale(cr, n, n)
    cairo_set_source_surface(cr, img, 0, 0)
    cairo_paint(cr)
    cairo_surface_destroy(img)
    cairo_restore(cr)
end

function print_barb(cr, x, y, d)
    if d[2] > 337 then
	r = d[1]*8
    else
	r = math.floor(d[2]/45+0.5)+d[1]*8
    end
    print_icon(cr, x, y, utf8(0xe6a4+r))
end

function print_weather(cr, xml)
    for n, icon in pairs(xml.icon) do
	print_icons(cr, 120, 35, 0.48, icon)
    end
    cairo_save(cr)
    print_temp(cr, 140, 175, 1, xml.temp)
    print_text(cr, 20, 22, 2, 0, string.format('Mérési idő: %s', xml.time))
    print_text(cr, 655, 22, 3, 1, xml.city)
    print_text(cr, 1290, 22, 2, 2, string.format('Koordináták: %s', xml.location))
    print_text(cr, 130, 47, 2, 1, "Most")
    print_text(cr, 140, 195, 1, 1, xml.weather)

    print_icon(cr, 10, 70, utf8(0xe560))
    print_text(cr, 45, 70, 0, 0, xml.pressure)
    print_icon(cr, 10, 90, utf8(0xe561))
    print_text(cr, 45, 90, 0, 0, xml.cloud)
    print_icon(cr, 10, 110, utf8(0xe562))
    print_text(cr, 45, 110, 0, 0, xml.humidity)
    print_barb(cr, 10, 130, xml.wind)
    print_text(cr, 45, 130, 0, 0, xml.wind[3])
    print_icon(cr, 10, 150, utf8(0xe563))
    print_text(cr, 45, 150, 0, 0, xml.dewpoint)

    if xml.qpf[1] > 0 then
	print_icon(cr, 10, 170, utf8(0xe5a0+xml.qpf[2]))
	print_icon(cr, 225, 70, utf8(0xe5b0+xml.qpf[1]))
	print_text(cr, 45, 170, 0, 0, xml.qpf[3])
    end

    cairo_restore(cr)
end

function print_forecast(cr, xml)
    for i = 0,4 do
	for n, icon in pairs(xml.f_icon[i+1]) do
	    print_icons(cr, 140+210*(i+1), 40, 0.4, icon)
	end
	cairo_save(cr)
	cairo_translate(cr, 255+210*i, 0)
	print_temp(cr, 110, 165, 0, xml.f_htemp[i+1])
	print_temp(cr, 150, 175, 0, xml.f_ltemp[i+1])

	print_text(cr, 105, 47, 2, 1, xml.f_date[i+1])
	print_text(cr, 105, 195, 1, 1, xml.f_weather[i+1])

	print_icon(cr, 10, 70, utf8(0xe560))
	print_text(cr, 40, 70, 0, 0, xml.f_pressure[i+1])
	print_icon(cr, 10, 90, utf8(0xe561))
	print_text(cr, 40, 90, 0, 0, xml.f_cloud[i+1])
	print_icon(cr, 10, 110, utf8(0xe562))
	print_text(cr, 40, 110, 0, 0, xml.f_humidity[i+1])
	print_barb(cr, 10, 130, xml.f_wind[i+1])
	print_text(cr, 40, 130, 0, 0, xml.f_wind[i+1][3])
	print_icon(cr, 10, 150, utf8(0xe563))
	print_text(cr, 40, 150, 0, 0, xml.f_dewpoint[i+1])

	if xml.f_qpf[i+1][1] > 0 then
	    print_icon(cr, 10, 170, utf8(0xe5a0+xml.f_qpf[i+1][2]))
	    print_icon(cr, 180, 70, utf8(0xe5b0+xml.f_qpf[i+1][1]))
	    print_text(cr, 40, 170, 0, 0, xml.f_qpf[i+1][3])
	end
	cairo_restore(cr)
    end
end

function conky_draw_img()
    if conky_window==nil then return end
    local w=conky_window.width
    local h=conky_window.height
    local cs=cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, w, h)
    local cr=cairo_create(cs)

    json = require("cjson")

--    i = math.floor(os.time()/60)%4
    i = 0
    file = io.open(string.format('/home/laci/.conky/weather%d.xml', i), 'r')
    xml = json.decode(file:read())
    file:close()

    print_weather(cr, xml)
    print_forecast(cr, xml)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function conky_draw_bg()
    if conky_window==nil then return end
    local w=conky_window.width
    local h=conky_window.height
    local cs=cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, w, h)
    local cr=cairo_create(cs)
--    local img=cairo_image_surface_create_from_png("/home/laci/.conky/weather.png")
--    cairo_set_source_surface(cr, img, 0, 0)
--    cairo_paint(cr)

--    cairo_surface_destroy(img)

    cairo_move_to(cr,bg_corner,0)
    cairo_line_to(cr,w-bg_corner,0)
    cairo_curve_to(cr,w,0,w,0,w,bg_corner)
    cairo_line_to(cr,w,h-bg_corner)
    cairo_curve_to(cr,w,h,w,h,w-bg_corner,h)
    cairo_line_to(cr,bg_corner,h)
    cairo_curve_to(cr,0,h,0,h,0,h-bg_corner)
    cairo_line_to(cr,0,bg_corner)
    cairo_curve_to(cr,0,0,0,0,bg_corner,0)
    cairo_close_path(cr)
    cairo_set_source_rgba(cr,rgb_to_r_g_b(bg_colour,bg_alpha))
    cairo_fill(cr)

    cairo_move_to(cr,bg_corner,0)
    cairo_line_to(cr,w-bg_corner,0)
    cairo_curve_to(cr,w,0,w,0,w,bg_corner)
    cairo_line_to(cr,w,h-bg_corner)
    cairo_curve_to(cr,w,h,w,h,w-bg_corner,h)
    cairo_line_to(cr,bg_corner,h)
    cairo_curve_to(cr,0,h,0,h,0,h-bg_corner)
    cairo_line_to(cr,0,bg_corner)
    cairo_curve_to(cr,0,0,0,0,bg_corner,0)
    cairo_close_path(cr)

    cairo_set_source_rgba(cr,rgb_to_r_g_b(border_colour,bg_alpha))
    cairo_set_line_width(cr, 1)
    cairo_stroke(cr)

    cairo_move_to(cr,0,30)
    cairo_line_to(cr,w,30)

    cairo_move_to(cr,0,52)
    cairo_line_to(cr,w,52)

    cairo_move_to(cr,260,30)
    cairo_line_to(cr,260,h)

    cairo_move_to(cr,470,30)
    cairo_line_to(cr,470,h)

    cairo_move_to(cr,680,30)
    cairo_line_to(cr,680,h)

    cairo_move_to(cr,890,30)
    cairo_line_to(cr,890,h)

    cairo_move_to(cr,1100,30)
    cairo_line_to(cr,1100,h)

    cairo_set_source_rgba(cr,rgb_to_r_g_b(border_colour,bg_alpha))
    cairo_set_line_width(cr, 1)
    cairo_stroke(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function conky_main()
    conky_draw_bg()
    conky_draw_img()
end
