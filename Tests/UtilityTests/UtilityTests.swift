import XCTest
@testable import Utility

class TempDependency {
    func sample() {
        print("hello")
    }
}

final class UtilityTests: XCTestCase {
    @Inject var parent: Resolver

    func testConcurentDIInject() throws {
        Utility.config()
        let exp = expectation(description: "Loading stories")
        self.parent.register {
            DIComponent() { TempDependency()  as TempDependency }
        }
        
        DispatchQueue.global().async {
        for i in 1...10000 {
            
                self.parent.register {
                    let name = "Temp_\(i)"
                    DIComponent(name) { TempDependency()  as TempDependency }
                }
            }
        }
        
        
        for i in 1...10001 {
            DispatchQueue.global().async {
                if let temp: TempDependency = self.parent.component<TempDependency>()  {
                    temp.sample()
                }
                if i == 10001 {
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 10)
    }
}

