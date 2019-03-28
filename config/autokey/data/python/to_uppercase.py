import time
try:
    selText = clipboard.get_selection()
    time.sleep(0.2)
    keyboard.send_keys(selText.upper())

except:
    dialog.info_dialog(title='No text selected',
                       message='No text in X selection')
