note
	description: "CELL_EXECUTOR with its program run open to the tests."
	author: "Larry Rix"

class
	INSPECTABLE_EXECUTOR

inherit
	CELL_EXECUTOR
		export
			{ANY} execute_compiled
		end

create
	make

end
