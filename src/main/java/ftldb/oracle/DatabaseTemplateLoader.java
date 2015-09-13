/*
 * Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ftldb.oracle;


import freemarker.cache.StatefulTemplateLoader;

import java.io.IOException;
import java.io.Reader;
import java.sql.*;


/**
 * This class finds, checks and loads templates from an Oracle database executing registered
 * {@link CallableStatement}s. An instance is constructed with three specified calls:
 * <ul>
 *     <li>{@code templateFinderCall} finds a template by its name</li>
 *     <li>{@code templateLoaderCall} loads the template's source from the database</li>
 *     <li>{@code templateCheckerCall} checks the template's freshness - optional</li>
 * </ul>
 *
 * <p>The finder call looks as:
 * <pre>
 * {@code
 * {call ftldb_api.default_template_finder(?, ?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_finder} procedure in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * procedure default_template_finder(
 *   in_templ_name in varchar2,
 *   out_locator_xml out varchar2
 * );
 * }
 * </pre>
 *
 * <p>The loader call looks as:
 * <pre>
 * {@code
 * {call ftldb_api.default_template_loader(?, ?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_loader} procedure in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * procedure default_template_loader(
 *   in_locator_xml in varchar2,
 *   out_body out clob
 * );
 * }
 * </pre>
 *
 * <p>The checker call looks as:
 * <pre>
 * {@code
 * {call ftldb_api.default_template_checker(?, ?)}
 * }
 * </pre>
 *
 * <p>where the specification of the {@code default_template_checker} procedure in the {@code ftldb_api} package is:
 * <pre>
 * {@code
 * procedure default_template_checker(
 *   in_locator_xml in varchar2,
 *   out_timestamp out integer
 * );
 * }
 * </pre>
 *
 * <p>If the checker call is not set, {@link #getLastModified} always returns {@code System.currentTimeMillis()}.
 *
 */
public class DatabaseTemplateLoader implements StatefulTemplateLoader {


    private final Connection connection;
    private final String templateFinderCall;
    private final String templateLoaderCall;
    private final String templateCheckerCall;
    private CallableStatement templateFinderCS;
    private CallableStatement templateLoaderCS;
    private CallableStatement templateCheckerCS;


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database.
     *
     * @param connection an opened connection to a database
     * @param templateFinderCall a call to the database that finds a template by its name
     * @param templateLoaderCall a call to the database that returns a template's source
     * @param templateCheckerCall a call to the database that gets a template's timestamp - optional (nullable)
     */
    public DatabaseTemplateLoader(Connection connection, String templateFinderCall, String templateLoaderCall,
                                  String templateCheckerCall ) {
        this.connection = connection;
        this.templateFinderCall = templateFinderCall;
        this.templateLoaderCall = templateLoaderCall;
        this.templateCheckerCall = (templateCheckerCall == null || "".equals(templateCheckerCall.trim()))
                                    ? null
                                    : templateCheckerCall;
    }


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database via the default driver's
     * connection.
     *
     * @param templateFinderCall a call to the database that finds a template by its name
     * @param templateLoaderCall a call to the database that returns a template's source
     * @param templateCheckerCall a call to the database that gets a template's timestamp - optional (nullable)
     * @throws SQLException if a database access error occurs
     */
    public DatabaseTemplateLoader(String templateFinderCall, String templateLoaderCall, String templateCheckerCall)
            throws SQLException {
        this(DriverManager.getConnection("jdbc:default:connection"),
                templateFinderCall, templateLoaderCall, templateCheckerCall);
    }


    /**
     * Creates an instance of {@link StatefulTemplateLoader} for working in a database via the default driver's
     * connection with disabled template timestamp checking.
     *
     * @param templateFinderCall a call to the database that finds a template by its name
     * @param templateLoaderCall a call to the database that returns a template's source
     * @throws SQLException if a database access error occurs
     */
    public DatabaseTemplateLoader(String templateFinderCall, String templateLoaderCall) throws SQLException {
        this(templateFinderCall, templateLoaderCall, null);
    }


    private CallableStatement getTemplateFinderCS() throws SQLException {
        if (templateFinderCS == null) {
            templateFinderCS = connection.prepareCall(templateFinderCall);
        }
        return templateFinderCS;
    }


    private CallableStatement getTemplateLoaderCS() throws SQLException {
        if (templateLoaderCS == null) {
            templateLoaderCS = connection.prepareCall(templateLoaderCall);
        }
        return templateLoaderCS;
    }


    private CallableStatement getTemplateCheckerCS() throws SQLException {
        if (templateCheckerCall == null) return null;

        if (templateCheckerCS == null) {
            templateCheckerCS = connection.prepareCall(templateCheckerCall);
        }
        return templateCheckerCS;
    }


    /**
     * Closes the inner {@link CallableStatement}s that are used for getting template sources.
     */
    public synchronized void resetState() {
        if (templateFinderCS != null) {
            try {
                templateFinderCS.close();
            } catch (SQLException ignored) {
            } finally {
                templateFinderCS = null;
            }
        }
        if (templateLoaderCS != null) {
            try {
                templateLoaderCS.close();
            } catch (SQLException ignored) {
            } finally {
                templateLoaderCS = null;
            }
        }
        if (templateCheckerCS != null) {
            try {
                templateCheckerCS.close();
            } catch (SQLException ignored) {
            } finally {
                templateCheckerCS = null;
            }
        }
    }


    /**
     * Executes the inner finder {@link CallableStatement} and gets the sought template's location.
     *
     * @param name the template's name
     * @return the template's locator
     * @throws IOException if a database access error occurs
     */
    public synchronized Object findTemplateSource(String name) throws IOException {
        try {
            CallableStatement tr = getTemplateFinderCS();
            tr.setString(1, name);
            tr.registerOutParameter(2, Types.VARCHAR); //locator as an XML string
            tr.execute();

            return tr.getString(2);
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to find template named " + name).initCause(e);
        }
    }


    /**
     * Executes the inner checker {@link CallableStatement} (if set) and gets the sought template's timestamp as a long
     * value. If the checker call is not set, returns current time.
     *
     * @param o the object storing the template's locator
     * @return the template's timestamp
     */
    public long getLastModified(Object o) {
        if (templateCheckerCall == null) return System.currentTimeMillis();

        String locator = (String) o;

        try {
            CallableStatement tc = getTemplateCheckerCS();
            tc.setString(1, locator);
            tc.registerOutParameter(2, Types.BIGINT);
            tc.execute();
            return tc.getLong(2);
        } catch (SQLException e) {
            throw new RuntimeException("Unable to check timestamp for template container", e);
        }
    }


    /**
     * Executes the inner loader {@link CallableStatement} and gets the sought template's source.
     *
     * @param o the object storing the template's location description
     * @return the template source as a {@link Reader} stream
     * @throws IOException if a database access error occurs
     */
    public synchronized Reader getReader(Object o, String encoding) throws IOException {
        String locator = (String) o;

        try {
            CallableStatement tl = getTemplateLoaderCS();
            tl.setString(1, locator);
            tl.registerOutParameter(2, Types.CLOB);
            tl.execute();
            return tl.getClob(2).getCharacterStream();
        } catch (SQLException e) {
            throw (IOException) new IOException("Unable to load template").initCause(e);
        }
    }


    /**
     * Actually does nothing.
     *
     * @param o the object storing the template's location description
     * @throws IOException never
     */
    public void closeTemplateSource(Object o) throws IOException { }


    private String formatCall(String call)  {
        if (call == null) return "null";

        String fc = call.replaceAll("\\s+", " ").trim();
        if (fc.length() > 100) fc = fc.substring(0, 100) + "...";
        return "\"" + fc + "\"";
    }


    /**
     * Returns the template loader name that is used in error log messages.
     *
     * @return the class name and the database calls
     */
    public String toString() {
        return this.getClass().getName() + "(templateFinderCall=" + formatCall(templateFinderCall) + "; "
                + "templateLoaderCall=" + formatCall(templateLoaderCall) + "; "
                + "templateCheckerCall=" + formatCall(templateCheckerCall) + ")";
    }


}
