---@module 'lazy'
---@type LazySpec
return
{
    'altermo/ultimate-autopair.nvim',
    event={'InsertEnter','CmdlineEnter'},
    branch='v0.6', --recommended as each new version will have breaking changes
    opts={
    fastwarp={
        multi=true,
        {},
        {faster=true,map='<C-A-y>',cmap='<C-A-y>'},
      }
    },
}
