////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////
package {

import flash.display.DisplayObject;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.events.Event;
import flash.system.Capabilities;

[Mixin]
/**
 *  A hash table of tests not to run, read from IncludeList.txt
 *  The file is one test per line of the form ScriptName$TestID
 *  The location of the file is assumed to be c:/tmp on windows, 
 *  or /tmp on Unix
 */
public class IncludeFileLocation
{

	private static var loader:URLLoader;

	/**
	 * tell UnitTester it should wait for this load to complete
	 */
	UnitTester.waitForIncludes = true;

	/**
	 *  Mixin callback that gets everything ready to go.
	 *  Table is of form: ScriptName$TestID: 1,
	 */
	public static function init(root:DisplayObject):void
	{


		var currentOS:String = Capabilities.os;

		var useFile:String;

		if (currentOS.indexOf ("Windows") != -1)
		{
			useFile = "c:/tmp/IncludeList.txt";	
		} else { 

			useFile = "/tmp/IncludeList.txt";	

		}


		var req:URLRequest = new URLRequest(useFile);
		loader = new URLLoader();
		loader.addEventListener("complete", completeHandler);
		loader.load(req);

	}

	private static function completeHandler(event:Event):void
	{
		var data:String = loader.data;
		// DOS end of line
		var delimiter:RegExp = new RegExp("\r\n", "g");
		data = data.replace(delimiter, ",");
		// Unix end of line
		delimiter = new RegExp("\n", "g");
		data = data.replace(delimiter, ",");

		UnitTester.includeList = new Object();
		var items:Array = data.split(",");
		var n:int = items.length;
		for (var i:int = 0; i < n; i++)
		{
			var s:String = items[i];
			if (s.length)
				UnitTester.includeList[s] = 1;
		}
		UnitTester.waitForIncludes = false;
		UnitTester.pre_startEventHandler(event);
	}
}

}
