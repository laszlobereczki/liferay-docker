#!/bin/bash

function assert_equals {
	local arguments=()

	for argument in "${@}"
	do
		arguments+=("${argument}")
	done

	local assertion_error_file="${PWD}/assertion_error"

	for index in ${!arguments[@]}
	do
		if [ $((index % 2)) -ne 0 ]
		then
			continue
		fi

		if [ -f "${arguments[${index}]}" ] &&
		   [ -f "${arguments[${index} + 1]}" ]
		then
			local temp_assertion_error_file="${PWD}/temp_assertion_error"

			diff \
				--side-by-side \
				--suppress-common-lines \
				"${arguments[${index}]}" "${arguments[${index} + 1]}" > "${temp_assertion_error_file}"

			if [ "${?}" -ne 0 ] && [ "${_TEST_RESULT}" == "true" ]
			then
				_TEST_RESULT="false"

				while IFS= read -r line
				do
					echo "Actual: $(echo "${line}" | cut -d '|' -f 1 | xargs)" >> "${assertion_error_file}"
					echo -e "Expected: $(echo "${line}" | cut -d '|' -f 2 | xargs)\n" >> "${assertion_error_file}"
				done < "${temp_assertion_error_file}"
			fi
		else
			if [ "${arguments[${index}]}" != "${arguments[${index} + 1]}" ]
			then
				if [ "${_TEST_RESULT}" == "true" ]
				then
					_TEST_RESULT="false"
				fi

				touch "${assertion_error_file}"

				echo -e "Actual: ${arguments[${index}]}\n" >> "${assertion_error_file}"
				echo -e "Expected: ${arguments[${index} + 1]}\n" >> "${assertion_error_file}"
			fi
		fi
	done

	if [ "${_TEST_RESULT}" == "true" ]
	then
		echo -e "${FUNCNAME[1]} \e[1;32mSUCCESS\e[0m\n"
	else
		echo -e "${FUNCNAME[1]} \e[1;31mFAILED\e[0m\n"

		cat "${assertion_error_file}"

		rm -f "${assertion_error_file}"

		_TEST_RESULT="true"
	fi
}

function main {
	_TEST_RESULT="true"

	if [ -n "${BASH_SOURCE[3]}" ]
	then
		echo -e "\n##### Running tests from $(echo ${BASH_SOURCE[3]} | sed -r 's/\.\///g') #####\n"
	elif [ -n "${BASH_SOURCE[2]}" ]
	then
		echo -e "\n##### Running tests from $(echo ${BASH_SOURCE[2]} | sed -r 's/\.\///g') #####\n"
	fi
}

main