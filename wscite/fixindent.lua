
--invert table for quick lookup
function table_invert(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

selstartpos = scite.SendEditor(SCI_GETSELECTIONSTART)
selstartline = scite.SendEditor(SCI_LINEFROMPOSITION, selstartpos)
selendline = scite.SendEditor(SCI_LINEFROMPOSITION, scite.SendEditor(SCI_GETSELECTIONEND))

text = editor:GetSelText()

--add each line to lines[] array
lines = {}
i = 1
for line = selstartline, selendline do
	linestart = scite.SendEditor(SCI_GETLINESELSTARTPOSITION, line) 
	lineend = scite.SendEditor(SCI_GETLINESELENDPOSITION, line)
	strtext = string.sub(text, linestart-selstartpos + 1, lineend - selstartpos)
	--if string.match(strtext, "[^%s]")~=nil then	--use if to get rid of blank lines
		lines[i] = strtext
		i = i + 1
	--end
end

--remove extra leading tabs
spacecount = {}
spaces = {}
for i = 1, #lines do
	spaces[i] = string.match(lines[i], "%s*[^%s]")
	if spaces[i]~=Null then
		spacecount[i] = string.len(spaces[i]) - 1
	else
		spacecount[i] = 0
	end
	print(spacecount[i])
end

tablevels = {}
for k, v in pairs(spacecount) do
	tablevels[k] = v
end

table.sort(tablevels)
j=#tablevels
while j>1 do
	if tablevels[j]==tablevels[j-1] then
		table.remove(tablevels, j)
	end
	j = j - 1
end

inv_tablevels = table_invert(tablevels)

for i = 1, #lines do
	if i ~= 1 then
		lines[i] = "\n" .. lines[i]
	end
	if spacecount[i]>0 then
		spacecount[i] = inv_tablevels[spacecount[i]] - 1
		lines[i] = string.gsub(lines[i], string.sub(spaces[i],1,-2), string.rep("\t", spacecount[i]), 1) 
	end
end

text=table.concat(lines)
editor:ReplaceTarget(text) 