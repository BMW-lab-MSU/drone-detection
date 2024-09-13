function titleCaseStr = titleCase(str)
    titleCaseStr = join([upper(extractBefore(str, 2)), extractAfter(str,1)],"");
end