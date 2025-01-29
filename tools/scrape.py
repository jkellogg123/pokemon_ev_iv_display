import sys
import pyperclip
import requests
from bs4 import BeautifulSoup

# Used to scrape bulbapedia pages to make the lua tables. Pretty messy, clearly ChatGPT.

def main():
    # url = "https://bulbapedia.bulbagarden.net/wiki/List_of_Pok%C3%A9mon_by_index_number_in_Generation_IV"
    # url = "https://bulbapedia.bulbagarden.net/wiki/List_of_items_by_index_number_in_Generation_IV"
    # url = "https://bulbapedia.bulbagarden.net/wiki/List_of_moves"
    # # url = "https://bulbapedia.bulbagarden.net/wiki/Type"
    url = "https://bulbapedia.bulbagarden.net/wiki/Ability#List_of_Abilities"
    # # url = "https://bulbapedia.bulbagarden.net/wiki/Type#Type_effectiveness"
    # url = "https://pokemondb.net/type/old"
    # url = "https://bulbapedia.bulbagarden.net/wiki/Experience#Experience_at_each_level"

    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')

    # table = soup.find('table')
    table = soup.find_all('table')
    table = table[9]
    # print(table)
    # table = soup.find('table', {'class': 'wikitable'})

    # Extract the rows from the table (tr is table row)
    rows = table.find_all('tr')[2:]  # Skip the header row

    num_per_row = 5

    lua_table = "local ABILITY = {\n"
    longest = ""
    # Iterate through the rows and extract item data
    for i, row in enumerate(rows):
        cells = row.find_all('td')  # table data
        def h(i):
            return cells[i].text.strip().replace(',', "")
        ind = h(0)
        name = h(1)
        gen = h(-1)
        if gen == "V": break
        lua_table += f"[{ind}] = \"{name}\",".ljust(26)
        if i % num_per_row == (num_per_row - 1):
            lua_table += "\n"
        if len(name) > len(longest):
            longest = name

    lua_table += "}\n"

    cut_off = 150
    if len(lua_table) > cut_off * 2:
        print(lua_table[:cut_off])
        print("...")
        print(lua_table[-cut_off:])
    else:
        print(lua_table)
    # print(lua_table)
    try:
        pyperclip.copy(lua_table)
        print("Copied to clipboard!")
    except:
        pass

    print(f"Length: {len(lua_table)}\tBytes: {sys.getsizeof(lua_table)}\t lines: {lua_table.count('\n')}")
    print("Longest is:", longest, len(longest))


#     # Send GET request
#     url = "https://bulbapedia.bulbagarden.net/wiki/Type#Type_chart"
#     response = requests.get(url)
#     soup = BeautifulSoup(response.text, 'html.parser')

#     # Locate the type chart table
#     type_chart_table = soup.find_all('table')[1]

#     # Initialize type names (excluding ??? type with index 9)
#     types = [
#         'Normal', 'Fighting', 'Flying', 'Poison', 'Ground', 'Rock', 'Bug', 'Ghost', 'Steel', 
#         'Fire', 'Water', 'Grass', 'Electric', 'Psychic', 'Ice', 'Dragon', 'Dark', 'Fairy'
#     ]

#     # Initialize Lua table structure
#     lua_table = {}

#     # Iterate through the rows of the type chart
#     type_indices = list(range(18))
#     type_indices.remove(9)
#     for attacking_index, row in zip(type_indices, type_chart_table.find_all('tr')[2:-1]):  # Skip the header row
#         columns = row.find_all('td')
        
#         # Initialize dict for the current attacking type
#         lua_table[attacking_index] = {'weak': [], 'strong': [], 'ineff': []}
        
#         # Extract the type matchups
#         for i, column in enumerate(columns[:-1]):  # Skip the first column (attacking type)
#             matchup = column.get_text(strip=True)
#             if i > 8: i += 1    # skip ??? type
#             if matchup == '0×':  # Immune
#                 lua_table[attacking_index]['ineff'].append(i)
#             elif matchup == '½×':  # Weak
#                 lua_table[attacking_index]['weak'].append(i)
#             elif matchup == '2×':  # Strong
#                 lua_table[attacking_index]['strong'].append(i)

#     # Generate Lua table
#     lua_code = 'local TYPE_PROPERTY = {\n'
#     for i, data in lua_table.items():
#         lua_code += f"    [{i}] = {{\n"
#         for key, value in data.items():
#             value = '{' + str(value)[1:-1] + '}'
#             lua_code += f"        [\"{key}\"] = {value},\n"
#         lua_code += "    },\n"
#     lua_code += '}'

#     # Print the generated Lua table
#     print(lua_code)
#     pyperclip.copy(lua_code)
#     print("Copied to clipboard!")


if __name__ == "__main__":
    print()
    main()
    print()