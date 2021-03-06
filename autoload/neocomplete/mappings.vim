"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! neocomplete#mappings#define_default_mappings() "{{{
  inoremap <expr><silent> <Plug>(neocomplete_start_unite_complete)
        \ unite#sources#neocomplete#start_complete()
  inoremap <expr><silent> <Plug>(neocomplete_start_unite_quick_match)
        \ unite#sources#neocomplete#start_quick_match()
  inoremap <silent> <Plug>(neocomplete_start_omni_complete)
        \ <C-x><C-o><C-p>
  inoremap <silent> <Plug>(neocomplete_start_auto_complete)
        \ <C-r>=neocomplete#mappings#auto_complete()<CR><C-r>=
        \neocomplete#mappings#popup_post()<CR>
  inoremap <silent> <Plug>(neocomplete_start_manual_complete)
        \ <C-r>=neocomplete#mappings#manual_complete()<CR><C-r>=
        \neocomplete#mappings#popup_post()<CR>

  if !has('patch-7.4.653')
    " To prevent Vim's complete() bug.
    if mapcheck('<C-h>', 'i') ==# ''
      inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
    endif
    if mapcheck('<BS>', 'i') ==# ''
      inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
    endif
  endif
endfunction"}}}

function! neocomplete#mappings#auto_complete() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let cur_text = neocomplete#get_cur_text(1)
  let complete_pos =
        \ neocomplete#complete#_get_complete_pos(
        \ neocomplete.complete_sources)
  let base = cur_text[complete_pos :]

  let neocomplete.candidates = neocomplete#complete#_get_words(
        \ neocomplete.complete_sources, complete_pos, base)
  let neocomplete.complete_str = base

  " Start auto complete.
  call complete(complete_pos+1, neocomplete.candidates)
  return ''
endfunction"}}}

function! neocomplete#mappings#manual_complete() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let cur_text = neocomplete#get_cur_text(1)
  let complete_sources = neocomplete#complete#_get_results(
        \ cur_text, neocomplete.manual_sources)
  let complete_pos =
        \ neocomplete#complete#_get_complete_pos(
        \ complete_sources)
  let base = cur_text[complete_pos :]

  let neocomplete.complete_pos = complete_pos
  let neocomplete.candidates = neocomplete#complete#_get_words(
        \ complete_sources, complete_pos, base)
  let neocomplete.complete_str = base

  " Start auto complete.
  call complete(complete_pos+1, neocomplete.candidates)
  return ''
endfunction"}}}

function! neocomplete#mappings#smart_close_popup() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  return neocomplete#mappings#cancel_popup()
endfunction
"}}}
function! neocomplete#mappings#close_popup() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.complete_str = ''
  let neocomplete.skip_next_complete = 2

  return pumvisible() ? "\<C-y>" : ''
endfunction
"}}}
function! neocomplete#mappings#cancel_popup() "{{{
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.complete_str = ''
  let neocomplete.skip_next_complete = 1

  return pumvisible() ? "\<C-e>" : ''
endfunction
"}}}

function! neocomplete#mappings#popup_post() "{{{
  return  !pumvisible() ? "" :
        \ g:neocomplete#enable_auto_select ? "\<C-p>\<Down>" : "\<C-p>"
endfunction"}}}

function! neocomplete#mappings#undo_completion() "{{{
  if !neocomplete#is_enabled()
    return ''
  endif

  let neocomplete = neocomplete#get_current_neocomplete()

  " Get cursor word.
  let complete_str =
        \ neocomplete#helper#match_word(neocomplete#get_cur_text(1))[1]
  let old_keyword_str = neocomplete.complete_str
  let neocomplete.complete_str = complete_str

  return (!pumvisible() ? '' :
        \ complete_str ==# old_keyword_str ? "\<C-e>" : "\<C-y>")
        \. repeat("\<BS>", len(complete_str)) . old_keyword_str
endfunction"}}}

function! neocomplete#mappings#complete_common_string() "{{{
  if !neocomplete#is_enabled()
    return ''
  endif

  " Get cursor word.
  let neocomplete = neocomplete#get_current_neocomplete()
  let neocomplete.event = 'mapping'
  let complete_str =
        \ neocomplete#helper#match_word(neocomplete#get_cur_text(1))[1]
  let neocomplete.event = ''

  if complete_str == ''
    return ''
  endif

  " Save options.
  let ignorecase_save = &ignorecase

  try
    if neocomplete#is_text_mode()
      let &ignorecase = 1
    elseif g:neocomplete#enable_smart_case
          \ || g:neocomplete#enable_camel_case
      let &ignorecase = complete_str !~ '\u'
    else
      let &ignorecase = g:neocomplete#enable_ignore_case
    endif

    let candidates = neocomplete#filters#matcher_head#define().filter(
          \ { 'candidates' : copy(neocomplete.candidates),
          \   'complete_str' : complete_str})

    if empty(candidates)
      let &ignorecase = ignorecase_save
      return ''
    endif

    let common_str = candidates[0].word
    for keyword in candidates[1:]
      while !neocomplete#head_match(keyword.word, common_str)
        let common_str = common_str[: -2]
      endwhile
    endfor

    if &ignorecase
      let common_str = tolower(common_str)
    endif
  finally
    let &ignorecase = ignorecase_save
  endtry

  if common_str == ''
        \ || complete_str ==? common_str
        \ || len(common_str) == len(candidates[0].word)
    return ''
  endif

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(complete_str)) . common_str
endfunction"}}}

function! neocomplete#mappings#fallback(i) "{{{
  let mapping = g:neocomplete#fallback_mappings[a:i]
  return  (pumvisible()
        \ || (mapping ==? "\<C-x>\<C-o>" && &l:omnifunc == '')) ? "" :
        \   mapping . "\<C-p>"
endfunction"}}}

" Manual complete wrapper.
function! neocomplete#mappings#start_manual_complete(...) "{{{
  if !neocomplete#is_enabled()
    return ''
  endif

  if neocomplete#helper#get_force_omni_complete_pos(
        \ neocomplete#get_cur_text(1)) >= 0
    return "\<C-x>\<C-o>"
  endif

  " Set context filetype.
  call neocomplete#context_filetype#set()

  let neocomplete = neocomplete#get_current_neocomplete()

  let sources = get(a:000, 0,
        \ keys(neocomplete#available_sources()))
  let neocomplete.manual_sources = neocomplete#helper#get_sources_list(
        \ neocomplete#util#convert2list(sources))
  let neocomplete.sources_filetype = ''

  call neocomplete#helper#complete_configure()

  " Start complete.
  return "\<C-r>=neocomplete#mappings#manual_complete()
        \\<CR>\<C-r>=neocomplete#mappings#popup_post()\<CR>"
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
