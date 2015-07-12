package com.asliceofcrazypie.flash.newJobs;

/**
 * ...
 * @author Zaphod
 */
class JobPool<T>
{
	private var _class:Class<T>;
	private var _pool:Array<T>;
	
	public function new(classObj:Class<T>) 
	{
		_class = classObj;
		_pool = new Array<T>();
		
	//	for (i in 0...5)
	//	{
	//		_pool.push(Type.createInstance(_class, []));
	//	}
	}
	
}