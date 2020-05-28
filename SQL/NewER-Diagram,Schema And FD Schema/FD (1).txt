DOMAIN(
d_name d_abbreviations p_name p_abbreviations b_name s_name b_name c_name code grade capacity s_login posistion clname credits s_idnr
)

FD:s
d_abbreviations -> d_name
s_idnr -> s_login s_name p_name b_name
s_login -> s_idnr
s_idnr code -> posistion grade
code -> c_name credits d_name capacity
code posistion -> s_idnr
p_name -> p_abbreviations 
d_name -> d_abbreviations




