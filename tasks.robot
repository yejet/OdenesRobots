*** Settings ***
Documentation       Odena robots desde RobotSpareBin Industries Inc.
...                 Guarda el recibo HTML en un PDF
...                 Guarda la captura del robot
...                 Incluye la captura en el PDF
...                 Crea un ZIP de los PDFs en el output

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${URL_Webpage}=                 https://robotsparebinindustries.com/#/robot-order
${URL_CSV}=                     https://robotsparebinindustries.com/orders.csv
${TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}temp
${PDFS_OUTPUT_DIRECTORY}=       ${CURDIR}${/}pdf


*** Tasks ***
Ordenar robot y recolectar informacion
    Crear directorios
    Abrir navegador web
    ${orders}=    Descargar CSV
    FOR    ${orden}    IN    @{orders}
        Completar formulario    ${orden}
    END
    Crear zip
    [Teardown]    Cerrar navegador y eliminar temp


*** Keywords ***
Abrir navegador web
    Open Available Browser    ${URL_Webpage}

Cerrar popup
    Click Button    OK

Descargar CSV
    Download
    ...    ${URL_CSV}
    ...    ${TEMP_OUTPUT_DIRECTORY}${/}orders.csv
    ...    overwrite=${True}
    ${orders}=    Read table from CSV    ${TEMP_OUTPUT_DIRECTORY}${/}orders.csv
    RETURN    ${orders}

Completar formulario
    # {'Order number': '1', 'Head': '1', 'Body': '2', 'Legs': '3', 'Address': 'Address 123'}
    [Arguments]    ${orden}
    Cerrar popup
    Select From List By Value    head    ${orden}[Head]
    Select Radio Button    body    id-body-${orden}[Body]
    Input Text    css:input[type='number'][placeholder='Enter the part number for the legs']    ${orden}[Legs]
    Input Text    address    ${orden}[Address]
    Click Button    preview
    # Wait for all to load
    Wait Until Element Is Visible    css:img[src='/heads/${orden}[Head].png']
    Wait Until Element Is Visible    css:img[src='/bodies/${orden}[Body].png']
    Wait Until Element Is Visible    css:img[src='/legs/${orden}[Legs].png']
    Screenshot    robot-preview-image    ${TEMP_OUTPUT_DIRECTORY}/order.png

    Wait Until Keyword Succeeds    5x    1 sec    Mandar orden    ${orden}[Order number]

Mandar orden
    [Arguments]    ${orderNumber}

    Click Button    order
    Wait Until Page Contains Element    id:receipt
    ${result_html}=    Get Element Attribute    id:receipt    outerHTML

    Html To Pdf    ${result_html}    ${TEMP_OUTPUT_DIRECTORY}${/}temp.pdf
    ${files}=    Create List
    ...    ${TEMP_OUTPUT_DIRECTORY}${/}temp.pdf
    ...    ${TEMP_OUTPUT_DIRECTORY}${/}order.png:format=Letter,align=center

    Add Files To Pdf    ${files}    ${PDFS_OUTPUT_DIRECTORY}/order-${orderNumber}.pdf    append=${True}

    Click Button    order-another

Cerrar navegador y eliminar temp
    Close Browser
    Remove Directory    ${TEMP_OUTPUT_DIRECTORY}    recursive=${True}
    Remove Directory    ${PDFS_OUTPUT_DIRECTORY}    recursive=${True}

Crear zip
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${PDFS_OUTPUT_DIRECTORY}    ${zip_file_name}

Crear directorios
    Create Directory    ${TEMP_OUTPUT_DIRECTORY}
    Create Directory    ${PDFS_OUTPUT_DIRECTORY}
