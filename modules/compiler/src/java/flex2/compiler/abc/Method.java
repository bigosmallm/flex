/*
 *
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package flex2.compiler.abc;

import flex2.compiler.util.QName;
import java.util.List;

/**
 * This interface defines the TypeTable API for a function.
 *
 * @author Clement Wong
 * @see flex2.compiler.as3.reflect.TypeTable
 * @see flex2.compiler.abc.AbcClass#getGetter(String[], String, boolean)
 * @see flex2.compiler.abc.AbcClass#getMethod(String[], String, boolean)
 * @see flex2.compiler.abc.AbcClass#getSetter(String[], String, boolean)
 */
public interface Method
{
    QName getQName();

    String getReturnTypeName();

    String getReturnElementTypeName();

    String[] getParameterTypeNames();

    String[] getParameterElementTypeNames();

    List<MetaData> getMetaData(String name);

    boolean isStatic();
    
    boolean isPublic();
    
}
