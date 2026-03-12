" Two-way diff each side of a file with Git conflict markers
" Maintainer: Seth House <seth@eseth.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

function! diffconflicts#hasConflicts() abort
    try
        silent execute "%s/^<<<<<<< //gn"
        return 1
    catch /Pattern not found/
        return 0
    endtry
endfunction

function! diffconflicts#diffconfl() abort
    let l:origBuf = bufnr("%")
    let l:origFt = &filetype

    if g:diffconflicts_vcs ==# "git"
        " Obtain the git setting for the conflict style.
        let l:conflictStyle = system("git config --get merge.conflictStyle")[:-2]
    else
        " Assume 2way conflict style otherwise.
        let l:conflictStyle = "diff"
    endif

    " Set up the right-hand side.
    rightb vsplit
    enew
    silent execute "read #" .. l:origBuf
    1delete
    silent execute "file RCONFL"
    silent execute "set filetype=" .. l:origFt
    diffthis " set foldmethod before editing
    silent execute "g/^<<<<<<< /,/^=======\\r\\?$/d"
    silent execute "g/^>>>>>>> /d"
    setlocal nomodifiable readonly buftype=nofile bufhidden=delete nobuflisted

    " Set up the left-hand side.
    wincmd p
    diffthis " set foldmethod before editing
    if l:conflictStyle ==? "diff3" || l:conflictStyle ==? "zdiff3"
        silent execute "g/^||||||| \\?/,/^>>>>>>> /d"
    else
        silent execute "g/^=======\\r\\?$/,/^>>>>>>> /d"
    endif
    silent execute "g/^<<<<<<< /d"

    diffupdate
endfunction

function! diffconflicts#showHistory() abort
    " Create the tab and windows.
    tabnew
    vsplit
    vsplit
    wincmd h
    wincmd h

    " Populate each window.
    if g:diffconflicts_vcs ==# "hg"
        buffer ~local.
        file LOCAL
    else
        buffer LOCAL
    endif
    setlocal nomodifiable readonly
    diffthis

    wincmd l
    if g:diffconflicts_vcs ==# "hg"
        buffer ~base.
        file BASE
    else
        buffer BASE
    endif
    setlocal nomodifiable readonly
    diffthis

    wincmd l
    if g:diffconflicts_vcs ==# "hg"
        buffer ~other.
        file OTHER
    else
        buffer REMOTE
    endif
    setlocal nomodifiable readonly
    diffthis

    " Put cursor in back in BASE.
    wincmd h
endfunction

function! diffconflicts#checkThenShowHistory() abort
    if g:diffconflicts_vcs ==# "hg"
        let l:filecheck = 'v:val =~# "\\~base\\." || v:val =~# "\\~local\\." || v:val =~# "\\~other\\."'
    else
        let l:filecheck = 'v:val =~# "BASE" || v:val =~# "LOCAL" || v:val =~# "REMOTE"'
    endif
    let l:xs =
                \ filter(
                \   map(
                \     filter(
                \       range(1, bufnr('$')),
                \       'bufexists(v:val)'
                \     ),
                \     'bufname(v:val)'
                \   ),
                \   l:filecheck
                \ )

    if (len(l:xs) < 3)
        echohl WarningMsg
                    \ | echo "Missing one or more of BASE, LOCAL, REMOTE."
                    \   .. " Was Vim invoked by a Git mergetool?"
                    \ | echohl None
        return 1
    else
        call diffconflicts#showHistory()
        return 0
    endif
endfunction

function! diffconflicts#checkThenDiff() abort
    if (diffconflicts#hasConflicts())
        redraw
        echohl WarningMsg
                    \ | echon "Resolve conflicts leftward then save. Use :cq to abort."
                    \ | echohl None
        return diffconflicts#diffconfl()
    else
        echohl WarningMsg | echo "No conflict markers found." | echohl None
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
