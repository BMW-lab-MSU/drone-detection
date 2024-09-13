function titleCaseStr = snakeCase2TitleCase(snakeCaseStr)
    titleCaseStr = join(titleCase(split(snakeCaseStr,'_')),"");
end