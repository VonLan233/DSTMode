local vox_language_set = GetModConfigData("vox_language_set")
local locale = LOC.GetLocaleCode()
_G['Vox language'] = true
if vox_language_set == 'AUTO' then
	_G['Vox language'] = locale == "en" or locale == "zhr" or locale == "zht" 
elseif vox_language_set == 'Chs' then
	_G['大狐狸语言'] = true
elseif vox_language_set == 'Eng' then
	_G['大狐狸语言'] = false
end

function _G.vox_loc(zh, en)
	return _G['大狐狸语言'] and zh or en
end