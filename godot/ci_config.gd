@tool
extends EditorScript

func _run() -> void:
	var settings = EditorInterface.get_editor_settings()
	var sdk = OS.get_environment("ANDROID_SDK_ROOT")
	var java = OS.get_environment("JAVA_HOME")
	print("ANDROID SDK: ", sdk)
	print("JAVA SDK: ", java)
	settings.set_setting("export/android/android_sdk_path", sdk)
	settings.set_setting("export/android/java_sdk_path", java)
	settings.save()
	print("Godot Android export paths configured.")
