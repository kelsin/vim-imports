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

" Option for eclipse location
if !exists("g:imports_eclipse_exe")
  let g:imports_eclipse_exe = "C:\\Program Files\\eclipse\\eclipse.exe"
endif

" Option for eclipse formatter preferences
if !exists("g:imports_eclipse_prefs")
  let g:imports_eclipse_prefs = "C:\\blizzard\\git\\configs\\org.eclipse.jdt.core.prefs"
endif

" Option for eclipse vm
if !exists("g:imports_eclipse_java")
  let g:imports_eclipse_java = "C:\\blizzard\\opt\\jdk1.7.0_45\\bin\\javaw.exe"
endif

" Autocmds to only create commands in java buffers
autocmd FileType java command! -buffer ImportsOrganize call imports#organize()
autocmd FileType java command! -buffer ImportsDeleteUnused call imports#delete_unused()
autocmd FileType java command! -buffer ImportsSort call imports#sort()
autocmd FileType java command! -buffer ImportsOpenJavadoc call imports#open_javadoc_under_cursor()
autocmd FileType java command! -buffer ImportsFind call imports#find_import_for_class_under_cursor() | noh
autocmd FileType java command! -buffer ImportsFormat call imports#format()
