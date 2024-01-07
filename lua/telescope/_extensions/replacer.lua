local has_telescope, telescope = pcall( require, "telescope" )

if not has_telescope then
    error( "Install nvim-telescope/telescope.nvim to use telescope-replacer plugin." )
end

local from_entry = require "telescope.from_entry"
local builtin = require( 'telescope.builtin' )
local actions = require( 'telescope.actions' )

local VIM_GREP = "--vimgrep"

local function add_flag( opts, flag )
    if not opts or not opts.additional_args then
        opts = opts or {}
        opts.additional_args = { flag }
    else
        if type( opts.additional_args ) == "function" then
            opts.additional_args = opts.additional_args( opts )
        end
        table.insert( opts.additional_args, flag )
    end
    return opts
end

return telescope.register_extension( {
    exports = {
        live_grep = function( opts )
            opts = add_flag( opts, VIM_GREP )
            builtin.live_grep( opts )
        end,
        live_grep_current_file = function( opts )
            opts = add_flag( opts, VIM_GREP )
            opts.search_dirs = { vim.api.nvim_buf_get_name( 0 ) }
            builtin.live_grep( opts )
        end,

        actions = {
            replace = function( prompt_bufnr, mode, target )
                local replacement = vim.fn.input( 'Replace selected entries with: ' )
                local action_state = require "telescope.actions.state"
                local picker = action_state.get_current_picker( prompt_bufnr )

                local prompt = vim.api.nvim_buf_get_lines( prompt_bufnr, 0, -1, false )[ 1 ]
                prompt = prompt:gsub( "> ", "" )

                local entries = picker:get_multi_selection()
                for i = #entries, 1, -1 do
                    local entry = entries[ i ]
                    local path = from_entry.path( entry, false, false )
                    local buffer_number = vim.fn.bufnr( path )

                    local file = io.open( path, "r" )
                    local lines = {}
                    for line in file:lines() do
                        table.insert( lines, line )
                    end
                    file:close()

                    local line = lines[ entry.lnum ]


                    local first = string.sub( line, 1, entry.col - 1 )
                    local second = string.sub( line, entry.col, -1 )

                    print( "first:", first )
                    print( "second:", second )

                    second = second:gsub( prompt, replacement, 1 )

                    lines[ entry.lnum ] = first .. second


                    print( "line:", lines[ entry.lnum ] )
                    file = io.open( path, "w" )
                    file:write( table.concat( lines, "\n" ) )
                    file:close()
                end

                actions.close( prompt_bufnr )
            end
        },
        setup = function( external_opts, _ )
        end,
    },
} )
