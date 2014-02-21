" imports.vim - Java Imports
" Author: Christopher Giroir <kelsin@valefor.com>
" Version: 0.0.1

if (exists("g:loaded_imports") && g:loaded_imports) || &cp
  finish
endif
let g:loaded_imports = 1

" Option for ordering imports
if !exists("g:imports_sort_order")
  let g:imports_sort_order="java,javax,net,org,com"
endif

" Returns true if this file includes at least one import statement
function! imports#has_imports()
  let l:view = winsaveview()

  " Search from the beginning to find the first import
  call cursor(1,0)
  let l:result = search('^import\ ', 'cn')

  " Restore view and return
  call winrestview(l:view)
  return l:result
endfunction

" Moves the cursor to where imports should start. This is the current line of
" the first import in the file if the file has imports, or at the beginnig (or
" right after a package line) if not.
function! imports#find_start()
  " Search from the beginning to find the first import
  call cursor(1,1)
  let l:start = imports#has_imports()

  " If we don't have one let's find a good replacement
  if l:start == 0
    let l:package=search('^package\ ', 'c')

    if l:package == 0
      " No package line either... let's just put imports FIRST
      let l:start = 1
    else
      " Append one line after the package line
      call append(l:package, "")

      " Delete all blanks
      exe "silent " . (l:package + 1) . ",/./-1d"

      " Append one line after the package line
      call append(l:package, "")

      " Set start to two lines after package
      let l:start = l:package + 2
    end
  endif

  call cursor(l:start, 1)
  return l:start
endfunction

" This function builds a import regex given a prefix
function! imports#regex(prefix)
  let l:prefix = a:prefix

  if !empty(a:prefix)
    let l:prefix = l:prefix . "\\."
  endif

  return "^import\\ " . l:prefix
endfunction

" Given a prefix, count how many import lines (that match that prefix) are ahead
" of the cursor. Does not count any imports before the cursor.
function! imports#count(prefix)
  let l:regex = imports#regex(a:prefix)

  let l:count = 0
  exe ",$g/" . l:regex . "/let l:count = l:count + 1"

  return l:count
endfunction

" Sorts the imports in the file according to g:imports_sort_order
function! imports#sort()
  " Don't do anything if there are no imports
  if imports#has_imports()
    " Save view to restore at the end
    let l:view = winsaveview()

    " Get import starting point and start there
    let l:start = imports#find_start()
    let l:current = l:start

    " Get sort order and loop over them
    let l:imports=split(g:imports_sort_order, ",")
    call add(l:imports, "")
    for l:prefix in l:imports
      " Save regex
      let l:regex = imports#regex(l:prefix)

      " Check to make sure we have imports of this type
      let l:search = search(l:regex, 'ncW')
      if l:search > 0
        " Move all matching imports to this starting point
        exe "g/" . l:regex . "/m " . (l:current - 1)

        " Count and sort
        let l:count = imports#count(l:prefix)
        exe l:current . "," (l:current + l:count - 1) . "sor u"
        let l:count = imports#count(l:prefix)

        " Insert one line after
        call append(l:current + l:count - 1, "")
        let l:current = l:current + l:count + 1
        call cursor(l:current, 1)
      endif
    endfor

    call cursor(l:current - 1, 1)
    call append(line("."), "")
    exe "silent " . l:current . ",/./-1d"

    call winrestview(l:view)
  endif
endfunction

" Delete any import whose class name (without package) doesn't appear in the
" rest of the file.
function! imports#delete_unused()
  let l:view = winsaveview()

  " Lets move to the beginning of the file and start searching for imports
  call cursor(1,1)
  let l:search = search('^import\ ', 'cW')
  while l:search > 0
    " Save current position of this search
    let l:line = line(".")
    let l:import = getline(l:line)
    let l:class = substitute(l:import, '^import\ .*\.\([^\.;]\+\);$', '\=submatch(1)', 'g')

    call cursor(l:line + 1, 1)
    let l:code = search('\<' . l:class . '\>', 'ncW')

    if l:code == 0
      " Not used, delete that line
      echom "Removing: " . l:import
      exe l:line . "d"
      call cursor(l:line, 1)
    endif

    let l:search = search('^import\ ', 'cW')
  endwhile

  call winrestview(l:view)
endfunction

" Runs DeleteUnusedImports and then SortImports
function! imports#organize()
  call imports#delete_unused()
  call imports#sort()
endfunction

" Grabs the word under the cursor and searches for an import for it. If found we
" return the fully qualified class name of this name.
function! imports#find_full_class_name()
  let l:class=expand("<cword>")

  " Search for that import
  let l:search=search("^import\\ .*" . l:class . ";", 'nc')
  if l:search != 0
    let l:line=getline(l:search)
    return substitute(l:line, '^import\ \(.*\);$', '\=submatch(1)', 'g')
  else
    return ""
  endif
endfunction

" Function to insert one import into the file.
function! imports#insert(import)
  let l:start = imports#find_start()

  call append(l:start-1, "import " . a:import . ";")
  call imports#sort()
  call search('^import\ ' . a:import . ';', '')
endfunction

" Function to find all importing options from .classtags if it exists
function! imports#get_options()
  let l:class=expand("<cword>")
  exe "silent vimgrep! /^" . l:class . ":/ .classtags"
  let l:matches=getqflist()
  if len(l:matches) > 0
    bd
    if len(l:matches) == 1
      return substitute(l:matches[0]['text'], '^\(.*\):\(.*\):\(.*\)$', '\=submatch(2) . "." . submatch(1)', 'g')
    else
      echo "More than 1"
    endif
  else
    echo "No Matches"
  endif
endfunction

" Commands {{{
autocmd FileType java command! -buffer ImportsOrganize call imports#organize()
autocmd FileType java command! -buffer ImportsDeleteUnused call imports#delete_unused()
autocmd FileType java command! -buffer ImportsSort call imports#sort()
" }}}
