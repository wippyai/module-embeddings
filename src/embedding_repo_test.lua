local test = require("test")
local sql = require("sql")
local uuid = require("uuid")
local env = require("env")
local embedding_repo = require("embedding_repo")

local function define_tests()
    describe("Embedding Repository", function()
        -- Test data for multiple origins and content types
        local origin_id_1 = uuid.v4()
        local origin_id_2 = uuid.v4()
        local context_id_1 = "test_context_a"
        local context_id_2 = "test_context_b"

        -- Sample embeddings (simplified for testing)
        local embedding_1 = {}
        local embedding_2 = {}
        local embedding_3 = {}
        local embedding_4 = {}
        local embedding_5 = {}

        -- Fill sample embeddings with random values
        for i = 1, 512 do
            embedding_1[i] = math.random() - 0.5
            embedding_2[i] = math.random() - 0.5
            embedding_3[i] = math.random() - 0.5
            embedding_4[i] = math.random() - 0.5
            embedding_5[i] = math.random() - 0.5
        end

        -- Clean up after all tests
        after_all(function()
            local db_resource, _ = env.get("wippy.embeddings:env-target_db")
            local db, err = sql.get(db_resource)
            if err then
                print("Warning: Could not connect to database for cleanup: " .. err)
                return
            end

            -- Delete all test entries
            local query = sql.builder.delete("embeddings_512")
                :where("content_type LIKE ?", "filter_test%")

            local executor = query:run_with(db)
            local result, err = executor:exec()

            if err then
                print("Warning: Could not clean up test embeddings: " .. err)
            else
                print("Cleaned up " .. result.rows_affected .. " test embeddings")
            end

            db:release()
        end)

        -- Test adding a single embedding
        it("should add a single embedding", function()
            local result, err = embedding_repo.add(
                "Document about machine learning algorithms for text classification.",
                "filter_test_document",
                origin_id_1,
                context_id_1,
                { category = "ml", importance = "high" },
                embedding_1
            )

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.entry_id).not_to_be_nil()
            expect(result.origin_id).to_equal(origin_id_1)
            expect(result.content_type).to_equal("filter_test_document")
            expect(result.context_id).to_equal(context_id_1)
        end)

        -- Test adding multiple embeddings in a batch
        it("should add multiple embeddings in a batch", function()
            local batch = {
                {
                    content = "Query about natural language processing techniques.",
                    content_type = "filter_test_query",
                    origin_id = origin_id_1,
                    context_id = context_id_1,
                    meta = { category = "nlp", importance = "medium" },
                    embedding = embedding_2
                },
                {
                    content = "Document about deep learning for image recognition.",
                    content_type = "filter_test_document",
                    origin_id = origin_id_1,
                    context_id = context_id_2,
                    meta = { category = "ml", importance = "high" },
                    embedding = embedding_3
                },
                {
                    content = "Document about database optimization techniques.",
                    content_type = "filter_test_document",
                    origin_id = origin_id_2,
                    context_id = context_id_1,
                    meta = { category = "db", importance = "high" },
                    embedding = embedding_4
                },
                {
                    content = "Query about SQL performance benchmarks.",
                    content_type = "filter_test_query",
                    origin_id = origin_id_2,
                    context_id = context_id_2,
                    meta = { category = "db", importance = "low" },
                    embedding = embedding_5
                }
            }

            local result, err = embedding_repo.add_batch(batch)

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.count).to_equal(#batch)
            expect(#result.items).to_equal(#batch)

            -- Check that each item has an entry_id
            for _, item in ipairs(result.items) do
                expect(item.entry_id).not_to_be_nil()
            end
        end)

        -- Test getting embeddings by origin_id
        it("should get embeddings by origin_id", function()
            local results, err = embedding_repo.get_by_origin(origin_id_1)

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()
            expect(#results).to_equal(3) -- 3 entries for origin_id_1

            -- Check that each result has the correct origin_id
            for _, result in ipairs(results) do
                expect(result.origin_id).to_equal(origin_id_1)
            end
        end)

        -- Test filtering by origin_id in search
        it("should filter search results by origin_id", function()
            -- We need a query embedding for search
            local query_embedding = embedding_1

            -- Search within origin_id_1
            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_1
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- All results should have origin_id_1
            for _, result in ipairs(results) do
                expect(result.origin_id).to_equal(origin_id_1)
            end

            -- Now search in origin_id_2
            results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_2
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- All results should have origin_id_2
            for _, result in ipairs(results) do
                expect(result.origin_id).to_equal(origin_id_2)
            end
        end)

        -- Test filtering by content_type
        it("should filter search results by content_type", function()
            -- Search for any content with content_type = filter_test_document
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                content_type = "filter_test_document"
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- All results should have content_type = filter_test_document
            for _, result in ipairs(results) do
                expect(result.content_type).to_equal("filter_test_document")
            end

            -- Now search for query content type
            results, err = embedding_repo.search_by_embedding(query_embedding, {
                content_type = "filter_test_query"
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- All results should have content_type = filter_test_query
            for _, result in ipairs(results) do
                expect(result.content_type).to_equal("filter_test_query")
            end
        end)

        -- Test filtering by context_id
        it("should filter search results by context_id", function()
            -- Search for content in context_id_1
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                context_id = context_id_1
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- All results should have context_id_1
            for _, result in ipairs(results) do
                expect(result.context_id).to_equal(context_id_1)
            end

            -- Now search in context_id_2
            results, err = embedding_repo.search_by_embedding(query_embedding, {
                context_id = context_id_2
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- All results should have context_id_2
            for _, result in ipairs(results) do
                expect(result.context_id).to_equal(context_id_2)
            end
        end)

        -- Test combining multiple filters
        it("should apply multiple filters correctly", function()
            -- Search with multiple filters: origin_id and content_type
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_1,
                content_type = "filter_test_document"
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()

            -- Results should match both filters
            for _, result in ipairs(results) do
                expect(result.origin_id).to_equal(origin_id_1)
                expect(result.content_type).to_equal("filter_test_document")
            end

            -- Test all three filters
            results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_2,
                content_type = "filter_test_query",
                context_id = context_id_2
            })

            expect(err).to_be_nil()

            -- Results should match all three filters
            for _, result in ipairs(results) do
                expect(result.origin_id).to_equal(origin_id_2)
                expect(result.content_type).to_equal("filter_test_query")
                expect(result.context_id).to_equal(context_id_2)
            end
        end)

        -- Test limit parameter
        it("should respect the limit parameter", function()
            -- Search with a limit of 2
            local query_embedding = embedding_1
            local limit = 2

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                limit = limit
            })

            expect(err).to_be_nil()
            expect(results).not_to_be_nil()
            expect(#results <= limit).to_be_true()
        end)

        -- Test deleting by entry_id
        it("should delete an embedding by entry_id", function()
            -- First get an embedding to delete
            local results, err = embedding_repo.get_by_origin(origin_id_1)
            expect(err).to_be_nil()
            expect(#results > 0).to_be_true()

            local entry_id = results[1].entry_id

            -- Now delete it
            local delete_result, err = embedding_repo.delete_by_entry(entry_id)
            expect(err).to_be_nil()
            expect(delete_result.deleted).to_be_true()

            -- Verify it's gone
            local all_results, err = embedding_repo.get_by_origin(origin_id_1)
            expect(err).to_be_nil()

            -- Check that the entry is no longer in the results
            local found = false
            for _, result in ipairs(all_results) do
                if result.entry_id == entry_id then
                    found = true
                    break
                end
            end
            expect(found).to_be_false()
        end)

        -- Test deleting by origin_id
        it("should delete all embeddings by origin_id", function()
            -- Delete all embeddings for origin_id_2
            local delete_result, err = embedding_repo.delete_by_origin(origin_id_2)
            expect(err).to_be_nil()
            expect(delete_result.deleted).to_be_true()
            expect(delete_result.count > 0).to_be_true()

            -- Verify they're gone
            local results, err = embedding_repo.get_by_origin(origin_id_2)
            expect(err).to_be_nil()
            expect(#results).to_equal(0)
        end)
    end)
end

return test.run_cases(define_tests)
