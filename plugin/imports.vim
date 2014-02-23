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

" Option for where system docs are stored
if !exists("g:imports_system_doc_root")
  let g:imports_system_doc_root = "http://docs.oracle.com/javase/7/docs/api/"
endif

" Option for where maven docs are stored
if !exists("g:imports_maven_doc_root")
  let g:imports_maven_doc_root = "target/apidocs/"
endif

" Autocmds to only create commands in java buffers
autocmd FileType java command! -buffer ImportsOrganize call imports#organize()
autocmd FileType java command! -buffer ImportsDeleteUnused call imports#delete_unused()
autocmd FileType java command! -buffer ImportsSort call imports#sort()
autocmd FileType java command! -buffer ImportsOpenJavadoc call imports#open_javadoc_under_cursor()
