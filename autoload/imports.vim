" imports.vim - Autoloaded Functions

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

function! imports#find_import_for_class_under_cursor()
  let l:class = expand('<cword>')
  let l:search=search("^import\\ .*" . l:class . ";", 'nc')
  if l:search != 0
    " Already have an import, we're done
    echo "Found import for " . l:class . " on line " . l:search
  else
    call imports#find_import_from_classtags(l:class)
  endif
endfunction

function! imports#find_import_from_classtags(class)
  let curr_buf = bufnr('%')
  split __imports_classtags__
  normal! ggdG
  setlocal filetype=text
  setlocal buftype=nofile
  call append(0, readfile(".classtags"))
  exe ":v/^" . a:class . ":/d"
  let l:results = line('$')
  if l:results == 0
    echo "Can't find a import for " . a:class
    bd
  elseif l:results == 1
    " Found the proper impot
    let l:import = substitute(getline('.'), '^\([^:]\+\):\([^:]\+\):.*$', '\=submatch(2).".".submatch(1)', '')
    bd
    call imports#insert(l:import)
  else
    exe ':%s/^\([^:]\+\):\([^:]\+\):.*$/\2\.\1/g'
    0
    nnoremap <buffer> <CR> :call imports#select()<CR>
  endif
endfunction

function! imports#select()
  let l:import = getline(".")
  bd
  call imports#insert(l:import)
endfunction

" Grabs the word under the cursor and searches for an import for it. If found we
" return the fully qualified class name of this name.
function! imports#find_full_class_name()
  let l:line = getline(".")
  if match(l:line, '^import\ ') >= 0
    return imports#find_full_class_name_from_import(l:line)
  else
    let l:class=expand("<cword>")

    " Search for that import
    let l:search=search("^import\\ .*" . l:class . ";", 'nc')
    if l:search != 0
      return imports#find_full_class_name_from_import(getline(l:search))
    else
      return ""
    endif
  endif
endfunction

function! imports#find_full_class_name_from_import(import)
  return substitute(a:import, '^import\ \(.*\);$', '\=submatch(1)', 'g')
endfunction

function! imports#find_class_name_from_full_class_name(fullclass)
  return substitute(a:fullclass, '^.*\.\([^\.]\+\)$', '\=submatch(1)', '')
endfunction

" Function to insert one import into the file.
function! imports#insert(import)
  let l:start = imports#find_start()

  call append(l:start-1, "import " . a:import . ";")
  call imports#sort()
  call search('^import\ ' . a:import . ';', '')
endfunction

function! imports#open_javadoc_under_cursor()
  let l:class = imports#find_full_class_name()
  if empty(l:class)
    call imports#google_javadoc(expand("<cword>"))
  else
    if match(l:class, '^java') >= 0
      call imports#open_system_javadoc(l:class)
    else
      call imports#open_maven_javadoc(l:class)
    endif
  endif
endfunction

function! imports#open_system_javadoc(class)
  call imports#open(imports#get_system_javadoc_file(a:class))
endfunction

function! imports#open_maven_javadoc(class)
  let l:url = substitute(a:class, '\.', '/', 'g')
  let l:file = g:imports_maven_doc_root . l:url . ".html"
  if filereadable(l:file)
    call imports#open(l:file)
  else
    call imports#google_javadoc(a:class)
  endif
endfunction

function! imports#get_system_javadoc_file(class)
  let l:url = substitute(a:class, '\.', '\', 'g')
  return g:imports_system_doc_root . l:url . ".html"
endfunction

function! imports#google_javadoc(class)
  call imports#google("javadoc+" . imports#find_class_name_from_full_class_name(a:class))
endfunction

function! imports#google(search)
  call imports#open("https://www.google.com/\\#q=" . a:search)
endfunction

" Function to open a string using the OS open/start features
function! imports#open(str)
  if has("win32")
    exe "!start /b start " . a:str
  endif
endfunction
