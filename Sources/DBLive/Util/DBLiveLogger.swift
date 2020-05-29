//
//  DBLiveLogger.swift
//  
//
//  Created by Mike Richards on 5/22/20.
//

public enum DBLiveLoggerLevel: Int
{
	case debug = 0
	case info = 1
	case warn = 2
	case error = 3
	case none = 4
	
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
			case .none:
				return "NONE"
			}
		}
	}
}

final public class DBLiveLogger
{
	public static var logLevel: DBLiveLoggerLevel = .none
	
	public var logLevel: DBLiveLoggerLevel {
		get { return _logLevel ?? DBLiveLogger.logLevel }
		set { _logLevel? = newValue }
	}
	
	private let name: String
	
	private var _logLevel: DBLiveLoggerLevel?
	
	init(_ name: String) {
		self.name = name
	}
	
	func debug(_ message: @autoclosure () -> String) {
		guard doLog(level: .debug) else { return }

		commitLog(message(), level: .debug)
	}
	
	func info(_ message: @autoclosure () -> String) {
		guard doLog(level: .info) else { return }

		commitLog(message(), level: .info)
	}
	
	func warn(_ message: @autoclosure () -> String) {
		guard doLog(level: .warn) else { return }
		
		commitLog(message(), level: .warn)
	}
	
	func error(_ message: @autoclosure () -> String) {
		guard doLog(level: .error) else { return }

		commitLog(message(), level: .error)
	}
	
	func log(_ message: @autoclosure () -> String, level: DBLiveLoggerLevel = .debug) {
		guard doLog(level: level) else { return }

		commitLog(message(), level: level)
	}
	
	private func commitLog(_ message: @autoclosure () -> String, level: DBLiveLoggerLevel) {
		print("\(name) \(level.stringValue): \(message())")
	}
	
	private func doLog(level: DBLiveLoggerLevel) -> Bool {
		return level.rawValue >= logLevel.rawValue
	}
}
