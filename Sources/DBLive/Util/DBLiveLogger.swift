//
//  DBLiveLogger.swift
//  
//
//  Created by Mike Richards on 5/22/20.
//

enum DBLiveLoggerLevel: Int
{
	case debug = 0
	case info = 1
	case warn = 2
	case error = 3
	
	var stringValue: String {
		get
		{
			switch(self) {
			case .debug:
				return "DEBUG"
			case .info:
				return "INFO"
			case .warn:
				return "WARN"
			case .error:
				return "ERROR"
			}
		}
	}
}

final class DBLiveLogger
{
	static var doLog = false
	
	var doLog: Bool {
		get { return _doLog || DBLiveLogger.doLog }
		set { _doLog = newValue }
	}
	
	private let name: String
	
	private var _doLog = false
	
	init(_ name: String) {
		self.name = name
	}
	
	func debug(_ message: @autoclosure () -> String) {
		guard doLog else { return }

		commitLog(message(), level: .debug)
	}
	
	func info(_ message: @autoclosure () -> String) {
		guard doLog else { return }

		commitLog(message(), level: .info)
	}
	
	func warn(_ message: @autoclosure () -> String) {
		guard doLog else { return }
		
		commitLog(message(), level: .warn)
	}
	
	func error(_ message: @autoclosure () -> String) {
		guard doLog else { return }

		commitLog(message(), level: .error)
	}
	
	func log(_ message: @autoclosure () -> String, level: DBLiveLoggerLevel = .debug) {
		guard doLog else { return }

		commitLog(message(), level: level)
	}
	
	private func commitLog(_ message: @autoclosure () -> String, level: DBLiveLoggerLevel) {
		print("\(name) \(level.stringValue): \(message())")
	}
}
