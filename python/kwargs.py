def greet_me(**kwargs):

    valid_kwarg = ['name', 'dreamer']
    for kwarg in kwargs.keys():
        if kwarg not in valid_kwarg:
            print('not valid')
    
    names = ['promise', 'owolabi']
    for key, value in kwargs.items():
        if key == 'name' and value not in names:
            print('name is not in valid names list')
        
    query = '?'
    for key, value in kwargs.items():
        query = query+("{}={}".format(key, value)+'&')
        print(query)
 
# greet_me(name="promise", dreamer='Joseph')

def words(name=None, title=None, location=None, room=None):
    param = {'name':name,
             'title':title, 
             'location':location, 
             'room':room}
    
    param = {key : value for key, value in param.items() if value != None}
    print(param)

    query = ''
    for key, value in param.items():
        query = query+("{}={}".format(key, value)+'&')
    return query

test = words(name='promise', title='Joseph')
print(test)




