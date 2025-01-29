# generate csv file for bulk entra create
import pandas as pd 

def licenseID(license):
    if license == 'Microsoft 365 A3 for students use benefit': 
        return '18250162-5d87-4436-a834-d795c15c80f3'
    elif license == 'Office 365 A1 for faculty':
        return '94763226-9b3c-4e75-a931-5c89701abe66'
    else: 
        print('License not found')
        return None

def generate_password():
    import random
    word_bank = word_bank = [
        'ball', 'bear', 'bike', 'bird', 'book', 'cake', 'call', 'card', 'care', 'cats',
        'cook', 'cool', 'desk', 'door', 'draw', 'duck', 'farm', 'fish', 'flag', 'flow',
        'food', 'game', 'gift', 'girl', 'gold', 'good', 'hand', 'help', 'hero', 'home',
        'hope', 'jump', 'kind', 'king', 'kite', 'lamp', 'leaf', 'life', 'lion', 'love',
        'moon', 'nice', 'note', 'park', 'play', 'rain', 'read', 'rock', 'room', 'rose',
        'safe', 'sand', 'seed', 'ship', 'sing', 'snow', 'soil', 'song', 'star', 'stay',
        'sun', 'swim', 'tall', 'team', 'time', 'tree', 'true', 'walk', 'wave', 'wind',
        'wish', 'wood', 'work', 'year', 'zero', 'zoom', 'blue', 'pink', 'gold', 'mint'
    ]
    word = random.choice(word_bank)
    num = random.randint(1000, 9999)
    pwd = word + str(num) + "!"
    return pwd

def normalize_name(name):
    n = name.split()
    if len(n) > 2: 
        display_name = input('Manually enter display name for ' + name + ': ')
    else:
        display_name = name
    return display_name

def process_data(data):
    pop_df = pd.DataFrame(columns=['DisplayName', 'UserPrincipalName', 'PasswordProfile_password', 'LicenseSkuId'])

    for index, row in data.iterrows():
        display_name = normalize_name(row['DisplayName']) 
        user_principal_name = display_name.lower().replace(', ', '').replace(' ', '') + '@penguincoding.org'
        password = generate_password()
        license_id = row['LicenseSkuId']
        # license_id = licenseID(row['SkuId']) 

        new_row = pd.DataFrame({
            'DisplayName': [display_name],
            'UserPrincipalName': [user_principal_name],
            'PasswordProfile_password': [password],
            'LicenseSkuId': [license_id]
        })
        pop_df = pd.concat([pop_df, new_row], ignore_index=True)
    return pop_df

if __name__ == '__main__': 
    new_users = 'user_data.csv'
    given_df = pd.read_csv(new_users)

    print("Reading CSV with columns:", given_df.columns.tolist())
    print("First few rows:", given_df.head())

    rtrn_df = process_data(given_df)
    rtrn_df.to_csv('bulk_create.csv', index=False)
    print('file ready :)')


