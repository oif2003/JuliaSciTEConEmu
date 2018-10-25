--Functions
function table:invert()
--invert table for quick reverse lookup
   local s={}
   for k,v in pairs(self) do
     s[v]=k
   end
   return s
end

function cancelTabs(lines)
--Cancels out tabs with backspaces so multi-line code display properly in Julia
--The remaining tabs are then converted to spaces
--this is needed because tabs are "cumulative" in Julia during multi-line input 
	--remove extra leading tabs
	spacecount = {}
	spaces = {}
	for i = 1, #lines do
		spaces[i] = string.match(lines[i], "%s*%w")
		if spaces[i]~=Null then
			spacecount[i] = string.len(spaces[i]) - 1
		else
			spacecount[i] = 0
		end
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
	
	inv_tablevels = table.invert(tablevels)
	
	for i = 1, #lines do
		if spacecount[i]>0 then
			spacecount[i] = inv_tablevels[spacecount[i]] - 1
			lines[i] = string.gsub(lines[i], string.sub(spaces[i],1,-2), string.rep("\t", spacecount[i]), 1)
		end
	end
	
	--cancel out tabs with backspaces
	for i=1, #lines do
		tabstr = string.match(lines[i], "^\t+")
		lines[i] = lines[i] .. "\n"
		if tabstr ~= nil then
			tabcount = string.len(tabstr)
			lines[i] = lines[i] .. string.rep("\b", tabcount)
			--replace leading each tab with 4 spaces since accidently hitting tab gives you wall of text
			lines[i] = string.gsub(lines[i], "^\t*", string.rep(" ", tabcount*editor.TabWidth)) 
		end
	end

	return lines
end

function string:split(inSplitPattern, outResults)
--http://lua-users.org/wiki/SplitJoin
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, 
theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

------------------------------------------------------------------------
--Auto Execute
--output.ReadOnly = false	--for debugging
selstartpos = scite.SendEditor(SCI_GETSELECTIONSTART)
selendpos = scite.SendEditor(SCI_GETSELECTIONEND)
selstartline = scite.SendEditor(SCI_LINEFROMPOSITION, selstartpos)
selendline = scite.SendEditor(SCI_LINEFROMPOSITION, scite.SendEditor(SCI_GETSELECTIONEND))
lines = {}
--Case: Multi-select
if editor.Selections > 1 then
	text = editor:GetText()
	k = 1
	--look at each selection
	for i = 1, editor.Selections do
		selection = string.sub(text, editor.SelectionNStart[i-1] + 1, editor.SelectionNEnd[i-1])
		--break each selection down into lines
		string.split(selection, "\n", lines)
	end	
--Case: No selection
elseif selstartpos == selendpos then
	lines[1] = editor:GetCurLine()
	lines[1] = string.gsub(lines[1], "^%s+", "")	--removes leading blank
	lines[1] = string.gsub(lines[1], "\n", "")
--Case: Selection on same line
elseif selstartline == selendline then
	lines[1] = editor:GetSelText()
	lines[1] = string.gsub(lines[1], "^%s+", "")
	lines[1] = string.gsub(lines[1], "\n", "")
--Other (multi line select)
else
	text = editor:GetText()
	i = 1
	for line = selstartline, selendline do
		linestart = scite.SendEditor(SCI_GETLINESELSTARTPOSITION, line)
		if linestart >= 0 then	--linestart will be -1 if no selection is on this line
			lineend = scite.SendEditor(SCI_GETLINESELENDPOSITION, line)
			strtext = string.sub(text, linestart+1, lineend)
			if string.match(strtext, "[^%s]")~=nil then
				lines[i] = strtext
				i = i + 1
			end
		end
	end	
end


lines = cancelTabs(lines)  --Compensate for tabs with backspaces
text = table.concat(lines)
editor:CopyText(text)  --Send results to Clipboard

