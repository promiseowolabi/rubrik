import rubrik_cdm

data_management = dir(rubrik_cdm.data_management.Data_Management)
print([module for module in data_management if not module.startswith('_')])
