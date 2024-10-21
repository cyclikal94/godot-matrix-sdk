from pathlib import Path
import yaml
import itertools
import re

# Anyone want some spaghetti code 🍝

def camel_to_snake(camel_str):
    # Insert an underscore before each uppercase letter and convert the string to lowercase
    snake_str = re.sub(r'(?<!^)(?=[A-Z])', '_', camel_str).lower()
    return snake_str

def read_yaml(file_path):
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)
    return data


def iterate_yaml_files():
    folder_path = Path('yaml')

    # Get all .yaml and .yml files in the folder
    yaml_files = itertools.chain(folder_path.glob('*.yaml'), folder_path.glob('*.yml'))

    final_out_array = {}
    for file_path in yaml_files:
        yaml_data = read_yaml(file_path)
        final_out = """"""
        for path, methods in yaml_data['paths'].items():  # Iterate over path and its methods
            for http_method in methods:  # Iterate over HTTP methods for each path

                params = ""
                params_doc = ""
                extra = ""
                params_block = ""
                optional_params_block = ""
                if 'parameters' in methods[http_method]:
                    for parameter in methods[http_method]['parameters']:
                        if 'in' in parameter:
                            if parameter['in'] == "query" and 'required' in parameter:
                                if params_block == "":
                                    params_block = f"url_params = \"?{parameter['name']}=\" + str({parameter['name']})"
                                else:
                                    params_block = params_block + f" + \"&{parameter['name']}=\" + str({parameter['name']})"

                        type = ""
                        if parameter['schema']['type'] == 'string':
                            if 'required' in parameter:
                                type = "String"
                            else:
                                type = "String = \"\""
                                if optional_params_block == "":
                                    optional_params_block = f"optional_url_params = \"\" if str({parameter['name']}) == \"\" else \"{parameter['name']}=\" + str({parameter['name']})"
                                else:
                                    optional_params_block = optional_params_block + f"""\n\toptional_url_params = optional_url_params + ( \"\" if str({parameter['name']}) == \"\" else \"&{parameter['name']}=\" + str({parameter['name']}) )"""
                        elif parameter['schema']['type'] == 'integer':
                            if 'required' in parameter:
                                type = 'int'
                            else:
                                type = "int = -9999"
                                if optional_params_block == "":
                                    optional_params_block = f"optional_url_params = \"\" if _int_to_string({parameter['name']}) == \"\" else \"{parameter['name']}=\" + _int_to_string({parameter['name']})"
                                else:
                                    optional_params_block = optional_params_block + f"""\n\toptional_url_params = optional_url_params + ( \"\" if _int_to_string({parameter['name']}) == \"\" else \"&{parameter['name']}=\" + _int_to_string({parameter['name']}) )"""
                        elif parameter['schema']['type'] == 'boolean':
                            if 'required' in parameter:
                                type = "bool"
                            else:
                                type = "int = -9999"
                                if optional_params_block == "":
                                    optional_params_block = f"optional_url_params = \"\" if _int_to_bool_string({parameter['name']}) == \"\" else \"{parameter['name']}=\" + _int_to_bool_string({parameter['name']})"
                                else:
                                    optional_params_block = optional_params_block + f"""\n\toptional_url_params = optional_url_params + ( \"\" if _int_to_bool_string({parameter['name']}) == \"\" else \"&{parameter['name']}=\" + _int_to_bool_string({parameter['name']}) )"""
                        elif parameter['schema']['type'] == 'object':
                            if 'required' in parameter:
                                type = "Dictionary"
                            else:
                                type = "Dictionary = {}"
                                if optional_params_block == "":
                                    optional_params_block = f"optional_url_params = \"\" if {parameter['name']} == {{}} else \"{parameter['name']}=\" + str({parameter['name']})"
                                else:
                                    optional_params_block = optional_params_block + f"""\n\toptional_url_params = optional_url_params + ( \"\" if {parameter['name']} == {{}} else \"&{parameter['name']}=\" + str({parameter['name']}) )"""


                        if params == "":
                            params = parameter['name'] + ': ' + type
                        else:
                            params = params + ', ' + parameter['name'] + ': ' + type


                    for parameter in methods[http_method]['parameters']:
                        type = ""
                        if parameter['schema']['type'] == 'string':
                            if 'required' in parameter:
                                type = "String"
                            else:
                                type = "(Optional) String"
                        elif parameter['schema']['type'] == 'integer':
                            if 'required' in parameter:
                                type = 'int'
                            else:
                                type = "(Optional) int"
                        elif parameter['schema']['type'] == 'boolean':
                            if 'required' in parameter:
                                type = "bool"
                            else:
                                type = "(Optional) bool | Must be provided as int (where 0 is `false`, 1 is `true`)"
                        elif parameter['schema']['type'] == 'object':
                            if 'required' in parameter:
                                type = 'Dictionary'
                            else:
                                type = "(Optional) Dictionary"

                        if params_doc == "":
                            params_doc = f"""\n##
## Parameters:
## - {parameter['name']}: {type} - {parameter['description'].replace("\n", "\n##\t\t")}\n"""
                        else:
                            params_doc = params_doc + '## - ' + parameter['name'] + ': ' + type + ' - ' + parameter['description'].replace("\n", "\n##\t\t") + '\n'

                    if params_doc.endswith('\n'):
                        params_doc = params_doc[:-1]


                    if http_method == 'put' or http_method == 'post':
                        extra = f"\n## - data: Dictionary"
                        if 'requestBody' in methods[http_method]:
                            if 'description' in methods[http_method]['requestBody']:
                                extra = extra + f" - {methods[http_method]['requestBody']['description'].replace("\n", " ")}"

                            if 'example' in methods[http_method]['requestBody']['content']['application/json']['schema']:
                                extra = extra + f" - {methods[http_method]['requestBody']['content']['application/json']['schema']['example']}"
                            elif 'properties' in methods[http_method]['requestBody']['content']['application/json']['schema']:
                                extra = extra + f" - {methods[http_method]['requestBody']['content']['application/json']['schema']['properties']}"

                if http_method == 'put' or http_method == 'post':
                    if params == "":
                        params = 'data: Dictionary'
                    else:
                        params = 'data: Dictionary, ' + params

                if params_block != "":
                    params_block = f"""\n\tvar url_params: String = \"\"
\t{params_block}"""
                if optional_params_block != "":
                    optional_params_block = f"""\n\tvar optional_url_params: String = \"\"
\t{optional_params_block}"""

                if params_block == "" and optional_params_block == "":
                    url_params_string = ""
                elif params_block != "" and optional_params_block == "":
                    url_params_string = " + url_params"
                elif params_block == "" and optional_params_block != "":
                    url_params_string = " + optional_url_params"
                elif params_block != "" and optional_params_block != "":
                    url_params_string = " + url_params + optional_url_params"
                else:
                    url_params_string = ""

                if url_params_string != "":
                    url_params_string = " + \"?\"" + url_params_string

                first = f"""## {methods[http_method]['summary'].replace("\n", " ")}
## {methods[http_method]['description'].replace("\n", "\n##\t\t") if 'description' in methods[http_method] else ""}{params_doc}{extra}
func {camel_to_snake(methods[http_method]['operationId'])}({params}) -> MatrixClientServerResponse:{params_block}{optional_params_block}
"""

                updated_path = path.replace("{", "\" + ").replace("}", " + \"")
                # if updated_path.endswith(' + "'):
                #     updated_path = updated_path[:-4]

                put_data_json_lines = ""
                if http_method == 'put' or http_method == 'post':
                    put_data_json_lines = f"""\n\tvar request_body: String = JSON.stringify(data)"""
                # else:
                #     put_data_json_lines = f"""\n\tvar json: JSON = JSON.new()"""

                put_data_json_extra = ""
                if http_method == 'put' or http_method == 'post':
                    put_data_json_extra = f", request_body"

                middle = f"""\tvar http_request: HTTPRequest = _request()
\tvar url = homeserver + "{yaml_data['servers'][0]['variables']['basePath']['default']}" + "{updated_path}"{url_params_string}{put_data_json_lines}
\tvar request = http_request.request(url, headers, HTTPClient.METHOD_{http_method.upper()}{put_data_json_extra})

\tif request != OK:
\t\thttp_request.queue_free()
\t\treturn MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

\tvar http_response : Array = await http_request.request_completed
\tvar json: JSON = JSON.new()
\tvar json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

\tif json_parsed != OK:
\t\thttp_request.queue_free()
\t\treturn MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

\tvar response_body: Dictionary = json.get_data()
\tvar output : Dictionary = {{
\t\t"response_status": http_response[0],
\t\t"response_code": http_response[1],
\t\t"headers": http_response[2],
\t\t"body": response_body,
\t}}

\thttp_request.queue_free()

\tif output.response_code == 401:
\t\treturn MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)"""

                resp = """"""
                for response, details in methods[http_method]['responses'].items():
                    if response == '200':
                        code = 'OK'
                    else:
                        code = 'FAILED'

                    if resp == """""":
                        resp = f"""\telif output.response_code == {response}:
\t\treturn MatrixClientServerResponse.new({code}, "{details['description'].replace("\n", " ")}", output)\n"""
                    else:
                        resp = resp + f"""\telif output.response_code == {response}:
\t\treturn MatrixClientServerResponse.new({code}, "{details['description'].replace("\n", " ")}", output)\n"""
                last = resp

                if last.endswith('\n'):
                    last = last[:-1]

                result = f"""{first.strip()}
{middle}
{last}
\telse:
\t\treturn MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)\n\n"""

                final_out = final_out + result

        final_out_array[file_path.stem] = [yaml_data['info']['title'], final_out]

    out = """"""
    for key, value in final_out_array.items():
        border = '#' * (value[0].__len__() + 6)
        out = out + border + '\n## ' + value[0] + ' ##\n' + border + '\n\n' + value[1] + '\n'

    with open("output.txt", "w") as file:
        file.write(out)

iterate_yaml_files()