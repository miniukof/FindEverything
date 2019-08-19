" File: FindEverything.vim
" Ogirinal Author: szwchao (szwchao@gmail.com)
" Description: Everything is a great search engine in windows.
"              It can locates files and folders by filename instantly.
"              This script provide a interface with everything command-line
"              tools(es.exe).
" Usage: 1. Download Everything gui and command-line(es.exe) tools
"           from the website: http://www.voidtools.com
"        2. Start everything.exe and keep it running on background.
"        4. Open vim and run command ":FE"
" Version: 1.1
" Last Modified: 2018 07 16

" Prevent reloading{{{
if exists('g:find_everything')
    finish
endif
let g:find_everything = 1
"}}}

" Only working in windows {{{
if (!has("win32") && !has("win95") && !has("win64") && !has("win16"))
    finish
endif
"}}}

" FindEverything {{{
fun! s:Handle_String(string)
    let l:str = a:string
    "trim
    let l:str = substitute(l:str, '^[[:blank:]]*\|[[:blank:]]*$', '', 'g')
    "if there is any space in file name, enclosed by double quotation
    if len(matchstr(l:str, " "))
        "don't add backslash before any white-space
        let l:str = substitute(l:str, '\\[[:blank:]]\+', " ", "g")
        let l:str = '"'.l:str.'"'
    endif
    return l:str
endfun

fun! FindEverything(search_pattern, directory)
    let cmd = "es"

    if !len(a:search_pattern)
        return
    endif

    let pattern = s:Handle_String(a:search_pattern)

    if len(a:directory)
        let cmd = cmd .' -path ' . a:directory . ' ' . pattern
    else
        let cmd = cmd . ' ' . pattern
    endif

    let l:result=system(cmd)

    if empty(l:result)
        echoh Error | echo "No files found!" | echoh None
        return
    endif
    if matchstr(l:result, 'Everything IPC window not found, IPC unavailable.') != ""
        echoh Error | echo "Everything.exe is not running!" | echoh None
        return
    endif

    " Show results
    call s:Show_Everything_Result(l:result)
endfun

fun! FindEverythingCurrent(search_pattern)
    call FindEverything(a:search_pattern, getcwd())
endfun

fun! FindEverythingAll(search_pattern)
    call FindEverything(a:search_pattern, "")
endfun

"}}}

" ToggleFEResultWindow {{{
fun! ToggleFEResultWindow()
    let bname = '_Everything_Search_Result_'
    let winnum = bufwinnr(bname)
    if winnum != -1
        if winnr() != winnum
            " If not already in the window, jump to it
            exe winnum . 'wincmd w'
            return
        else
            silent! close
            return
        endif
    endif

    let bufnum = bufnr(bname)
    if bufnum == -1
        echoh Error | echo "No FE results yet!" | echoh None
        let wcmd = bname
    else
        let wcmd = '+buffer' . bufnum
        exe 'silent! botright ' . '15' . 'split ' . wcmd
    endif
endfun
"}}}

"Show_Everything_Result {{{
fun! s:Show_Everything_Result(result)
    let bname = '_Everything_Search_Result_'
    " If the window is already open, jump to it
    let winnum = bufwinnr(bname)
    if winnum != -1
        if winnr() != winnum
            " If not already in the window, jump to it
            exe winnum . 'wincmd w'
        endif
        setlocal modifiable
        " Delete the contents of the buffer to the black-hole register
        silent! %delete _
    else
        let bufnum = bufnr(bname)
        if bufnum == -1
            let wcmd = bname
        else
            let wcmd = '+buffer' . bufnum
        endif
        exe 'silent! botright ' . '15' . 'split ' . wcmd
    endif
    " Mark the buffer as scratch
    setlocal buftype=nofile
    "setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    setlocal winfixheight
    setlocal modifiable

    " Setup the cpoptions properly for the maps to work
    let old_cpoptions = &cpoptions
    set cpoptions&vim
    " Create a mapping
    call s:Map_Keys()
    " Restore the previous cpoptions settings
    let &cpoptions = old_cpoptions
    " Display the result
    silent! %delete _
    silent! 0put =a:result

    " Delete the last blank line
    silent! $delete _
    " Move the cursor to the beginning of the file
    normal! gg
    setlocal nomodifiable
endfun
"}}}

"Map_Keys {{{
fun! s:Map_Keys()
    nnoremap <buffer> <silent> <CR>
                \ :call <SID>Open_Everything_File()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse>
                \ :call <SID>Open_Everything_File()<CR>
    nnoremap <buffer> <silent> <C-CR>
                \ :call <SID>Open_Everything_File()<CR>
    nnoremap <buffer> <silent> <ESC> :close<CR>
endfun
"}}}

"Open {{{
fun! s:Open(fname)
    let s:esc_fname_chars = ' *?[{`$%#"|!<>();&' . "'\t\n"
    let esc_fname = escape(a:fname, s:esc_fname_chars)
    let winnum = bufwinnr('^' . a:fname . '$')
    if winnum != -1
        " Automatically close the window
        silent! close
        " If the selected file is already open in one of the windows, jump to it
        let winnum = bufwinnr('^' . a:fname . '$')
        if winnum != winnr()
            exe winnum . 'wincmd w'
        endif
    else
        " Automatically close the window
        silent! close
        " Edit the file
        exe 'edit ' . esc_fname
    endif
endfun
"}}}

" Open_Everything_File {{{
fun! s:Open_Everything_File()
    let fname = getline('.')
    if fname == ''
        return
    endif

    call s:Open(fname)
endfun
"}}}

command! -nargs=1 FEA call FindEverythingAll(<f-args>)
command! -nargs=1 FEC call FindEverythingCurrent(<f-args>)
command! -nargs=* FER call ToggleFEResultWindow()

" vim:fdm=marker:fmr={{{,}}}
