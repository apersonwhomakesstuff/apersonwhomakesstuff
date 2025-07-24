local sin, cos, floor, max = math.sin, math.cos, math.floor, math.max

local function main()
    local A, B = 0, 0

    while true do
        local termWidth, termHeight = term.getSize()
        local bufferSize = termWidth * termHeight
        local z = {}
        local b = {}

        for i = 0, bufferSize - 1 do z[i] = 0.0 end
        for i = 0, bufferSize - 1 do b[i] = " " end

        for j = 0, 6.28, 0.07 do
            for i = 0, 6.28, 0.07 do
                local sini = sin(i)
                local cosj = cos(j)
                local sinA = sin(A)
                local sinj = sin(j)
                local cosA = cos(A)
                local cosj2 = cosj + 2
                local mess = 1 / (sini * cosj2 * sinA + sinj * cosA + 5)
                local cosi = cos(i)
                local cosB = cos(B)
                local sinB = sin(B)
                local t = sini * cosj2 * cosA - sinj * sinA

                local x = floor(termWidth / 2 + (termWidth / 2.7) * mess * (cosi * cosj2 * cosB - t * sinB))
                local y = floor(termHeight / 2 + (termHeight / 2.2) * mess * (cosi * cosj2 * sinB + t * cosB))
                local o = floor(x + termWidth * y)
                local N = floor(
                    8 *
                    ((sinj * sinA - sini * cosj * cosA) * cosB - sini * cosj * sinA - sinj * cosA - cosi * cosj * sinB)
                )

                if y < termHeight and y > 0 and x > 0 and x < termWidth and mess > z[o] then
                    z[o] = mess
                    local n = max(N, 1)
                    b[o] = (".,-~:;=!*#$@"):sub(n, n)
                end
            end
        end

        term.setCursorPos(1, 1)
        for y = 0, termHeight - 1 do
            local line = ""
            for x = 0, termWidth - 1 do
                local k = x + termWidth * y
                line = line .. (b[k] or " ")
            end
            print(line)
        end

        A = A + 0.04
        B = B + 0.02
        os.sleep(0.01)
    end
end

main()
