'Iniciamos creando la conexion con SAP
If Not IsObject(application) Then
   Set SapGuiAuto  = GetObject("SAPGUI")
   Set application = SapGuiAuto.GetScriptingEngine
End If
If Not IsObject(connection) Then
   Set connection = application.Children(0)
End If
If Not IsObject(session) Then
   Set session    = connection.Children(0)
End If
If IsObject(WScript) Then
   WScript.ConnectObject session,     "on"
   WScript.ConnectObject application, "on"
End If

On Error Resume Next
nameConstructor = "          "

'Funcion para entrar a la MMBE
Private  Function mmbeSap(PN, plant, mov):
    session.findById("wnd[0]/usr/ctxtMS_MATNR-LOW").text = PN
    session.findById("wnd[0]/usr/ctxtMS_WERKS-LOW").text = plant
    session.findById("wnd[0]/usr/ctxtMS_LGORT-LOW").text = mov
    session.findById("wnd[0]/usr/ctxtMS_LGORT-LOW").setFocus
    session.findById("wnd[0]/usr/ctxtMS_LGORT-LOW").caretPosition = 4
    session.findById("wnd[0]/tbar[1]/btn[8]").press
End Function

'Funcion para los errores
Private  Function ups(val)
   If Err.Number <> 0 Then
      ' La casilla no existe, maneja el error
      val = "Checar numero"
  End If
  
  ' Reinicia el objeto de error
  Err.Clear

End Function

' ------- AQUI INICIA TODO LO RELACIONADO AL .CSV -------------
'Abrimos el arvhivo
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("material.csv", 1) ' 1 para lectura

' Crear el diccionario
Set diccionario = CreateObject("Scripting.Dictionary")

' Saltar la primera línea (títulos)
objFile.SkipLine

' ------------- AQUI YA INICIA LA INTERACCION CON SAP ------------
Do Until objFile.AtEndOfStream
    ' Leer una línea del archivo
    line = objFile.ReadLine
    
    ' Dividir la línea en columnas usando la coma como delimitador
    columns = Split(line, ",")

    ' Obtener los valores de las columnas
    PN = columns(0)
    SOM = columns(1)
    ups SOM
    QNTY = columns(2)
    ups QNTY

    mmbeSap PN,"JM03", "001W"
    JM03001W = session.findById("wnd[0]/usr/cntlCC_CONTAINER/shellcont/shell/shellcont[1]/shell[1]").GetItemText(nameConstructor & "4", "C" & nameConstructor & "2")
    ups JM03001W
    session.findById("wnd[0]/tbar[0]/btn[3]").press
    
    mmbeSap PN,"JM03", "WIP1"
    JM03WIP = session.findById("wnd[0]/usr/cntlCC_CONTAINER/shellcont/shell/shellcont[1]/shell[1]").GetItemText(nameConstructor & "4", "C" & nameConstructor & "2")
    ups JM03WIP
    session.findById("wnd[0]/tbar[0]/btn[3]").press
    
    mmbeSap PN,"JM03", "0001"
    JM030001 = session.findById("wnd[0]/usr/cntlCC_CONTAINER/shellcont/shell/shellcont[1]/shell[1]").GetItemText(nameConstructor & "4", "C" & nameConstructor & "2")
    ups JM030001
    session.findById("wnd[0]/tbar[0]/btn[3]").press

    Set valores = CreateObject("Scripting.Dictionary")
    valores.Add "SOM", SOM
    valores.Add "QNTY", QNTY
    valores.Add "0001 JM03", JM030001
    valores.Add "001W JM03" , JM03001W
    valores.Add "WIP1 JM03", JM03WIP

    diccionario.Add PN, valores

Loop

' Cerrar el archivo
objFile.Close

' Crear un objeto Excel
Dim excelApp
Set excelApp = CreateObject("Excel.Application")

' Abrir un nuevo libro de Excel
Dim excelWorkbook
Set excelWorkbook = excelApp.Workbooks.Add()

' Obtener la primera hoja del libro
Dim excelWorksheet
Set excelWorksheet = excelWorkbook.Sheets(1)

' Escribir la cabecera en la primera fila
excelWorksheet.Range("A1:F1").Value = Array("PN", "SOM","Qnty", "0001 JM03", "001W JM03", "WIP1 JM03")

' Variables para el control de fila
Dim rowNum
rowNum = 2

' Recorrer el diccionario y escribir los valores en el archivo Excel
Dim key
For Each key In diccionario.Keys
    Dim valores
    Set valores = diccionario(key)
    
    excelWorksheet.Cells(rowNum, 1).Value = key
    excelWorksheet.Cells(rowNum, 2).Value = valores("SOM")
    excelWorksheet.Cells(rowNum, 3).Value = valores("QNTY")
    excelWorksheet.Cells(rowNum, 4).Value = valores("0001 JM03")
    excelWorksheet.Cells(rowNum, 5).Value = valores("001W JM03")
    excelWorksheet.Cells(rowNum, 6).Value = valores("WIP1 JM03")
    
    rowNum = rowNum + 1
Next

Dim objFSO, scriptPath, filePath
Set objFSO = CreateObject("Scripting.FileSystemObject")
scriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
filePath = scriptPath & "\recibos.xlsx"

' Guardar el archivo Excel en la misma carpeta que el script
excelWorkbook.SaveAs filePath

WScript.Echo "Termine, puedes encontrar el archivo en: " & filepath

excelWorkbook.Close
excelApp.Quit